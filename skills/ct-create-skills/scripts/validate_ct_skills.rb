#!/usr/bin/env ruby

require "yaml"
require "open3"
require "pathname"

errors = []
check_tracked = ARGV.delete("--tracked")
fail_on_contract_change = ARGV.delete("--fail-on-contract-change")
against_ref = nil
if (against_index = ARGV.index("--against"))
  against_ref = ARGV[against_index + 1]
  if against_ref.nil? || against_ref.start_with?("--")
    errors << "--against에는 비교할 Git ref가 필요합니다"
    ARGV.delete_at(against_index)
  else
    ARGV.slice!(against_index, 2)
  end
end
if fail_on_contract_change && against_ref.nil?
  errors << "--fail-on-contract-change는 --against <Git ref>와 함께 사용해야 합니다"
end
skills_root = File.expand_path(ARGV[0] || "../..", __dir__)
contract_changes = []
document_roots = %w[references templates workflow components].freeze
resource_roots = %w[scripts assets agents].freeze
reference_roots = (document_roots + resource_roots).freeze
orphan_roots = (document_roots + %w[scripts assets]).freeze

def markdown_references(content, roots)
  root_pattern = roots.join("|")
  without_fenced_code(content).lines.flat_map do |line|
    references = line.scan(/`((?:#{root_pattern})\/[^`\s]+)`/).flatten
    references.concat(line.scan(/\]\(((?:#{root_pattern})\/[^)\s]+)\)/).flatten)
    references.map { |reference| reference.split(/[?#]/, 2).first }
  end.uniq
end

def dynamic_reference?(reference)
  reference.match?(/\{[^}]+\}|<[^>]+>/)
end

def reference_covers?(reference, relative_path)
  return true if reference == relative_path
  return false unless dynamic_reference?(reference)

  pattern = reference.gsub(/\{[^}]+\}|<[^>]+>/, "*")
  File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME)
end

def frontmatter_content(content)
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  raise "frontmatter 구분자가 없습니다" unless match

  YAML.safe_load(match[1])
end

def frontmatter(path)
  frontmatter_content(File.read(path))
end

def without_fenced_code(content)
  fence_type = nil
  fence_length = 0

  content.lines.filter_map do |line|
    if fence_type
      marker = line.match(/^\s*(`{3,}|~{3,})\s*$/)&.[](1)
      if marker && marker[0] == fence_type && marker.length >= fence_length
        fence_type = nil
        fence_length = 0
      end
      next
    end

    marker = line.match(/^\s*(`{3,}|~{3,})/)&.[](1)
    if marker
      fence_type = marker[0]
      fence_length = marker.length
      next
    end

    line
  end.join
end

def contract_sections(content)
  sections = Hash.new { |hash, key| hash[key] = [] }
  current = nil

  without_fenced_code(content).lines.each do |line|
    if (heading = line.match(/^## (.+?)\s*$/))
      current = heading[1] == "이력관리" ? nil : heading[1]
      next
    end
    next unless current

    normalized = line.strip.gsub(/\s+/, " ")
    sections[current] << normalized unless normalized.empty?
  end

  sections.transform_values { |lines| lines.join("\n") }
end

repository_root = nil
if check_tracked || against_ref
  stdout, stderr, status = Open3.capture3("git", "-C", skills_root, "rev-parse", "--show-toplevel")
  if status.success?
    repository_root = stdout.strip
  else
    errors << "Git 검사를 위한 저장소 루트를 찾지 못했습니다 - #{stderr.strip}"
  end
end

if against_ref && repository_root
  _stdout, stderr, status = Open3.capture3(
    "git", "-C", repository_root, "rev-parse", "--verify", "#{against_ref}^{commit}"
  )
  unless status.success?
    errors << "계약 비교 Git ref를 확인할 수 없습니다 - #{against_ref}: #{stderr.strip}"
    against_ref = nil
  end
end

Dir.glob(File.join(skills_root, "ct-*"), File::FNM_DOTMATCH).sort.each do |skill_dir|
  next unless File.directory?(skill_dir)

  name = File.basename(skill_dir)
  skill_file = File.join(skill_dir, "SKILL.md")
  openai_file = File.join(skill_dir, "agents", "openai.yaml")
  interface_references = []

  unless File.file?(skill_file)
    errors << "#{name}: SKILL.md가 없습니다"
    next
  end

  begin
    metadata = frontmatter(skill_file)
    errors << "#{name}: frontmatter 키는 name, description만 허용합니다" unless metadata.keys.sort == %w[description name]
    errors << "#{name}: 폴더명과 name이 다릅니다" unless metadata["name"] == name
    errors << "#{name}: description이 비어 있습니다" if metadata["description"].to_s.strip.empty?
  rescue StandardError => e
    errors << "#{name}: SKILL.md YAML 오류 - #{e.message}"
  end

  if File.file?(openai_file)
    begin
      openai = YAML.safe_load(File.read(openai_file))
      interface = openai["interface"]
      policy = openai["policy"]
      unless interface.is_a?(Hash)
        errors << "#{name}: openai.yaml interface가 없습니다"
      else
        display_name = interface["display_name"].to_s
        short_description = interface["short_description"].to_s
        default_prompt = interface["default_prompt"].to_s
        errors << "#{name}: display_name이 비어 있습니다" if display_name.strip.empty?
        errors << "#{name}: short_description은 25~64자여야 합니다" unless (25..64).cover?(short_description.length)
        errors << "#{name}: default_prompt에 $#{name}이 없습니다" unless default_prompt.include?("$#{name}")

        implicit_invocation = policy.is_a?(Hash) ? policy["allow_implicit_invocation"] : nil
        unless implicit_invocation == true || implicit_invocation == false
          errors << "#{name}: policy.allow_implicit_invocation은 boolean이어야 합니다"
        end

        %w[icon_small icon_large].each do |key|
          icon = interface[key].to_s
          next if icon.empty?

          relative_icon = icon.sub(%r{\A\./}, "")
          interface_references << relative_icon
          target = File.join(skill_dir, relative_icon)
          errors << "#{name}: #{key} 파일이 없습니다 - #{icon}" unless File.file?(target)
        end
      end
    rescue StandardError => e
      errors << "#{name}: openai.yaml 오류 - #{e.message}"
    end
  else
    errors << "#{name}: agents/openai.yaml이 없습니다"
  end

  agent_files = Dir.glob(File.join(skill_dir, "agents", "**", "*"))
                   .select { |path| File.file?(path) }
  agent_files.each do |agent_file|
    relative = agent_file.delete_prefix("#{skill_dir}/")
    next if relative == "agents/openai.yaml"

    errors << "#{name}: agents에는 openai.yaml만 둘 수 있습니다 - #{relative}"
  end

  markdown_files = Dir.glob(File.join(skill_dir, "**", "*.md")).sort
  markdown_files.each do |markdown_file|
    current_heading = nil
    without_fenced_code(File.read(markdown_file)).lines.each do |line|
      current_heading = line[/^## (.+?)\s*$/, 1] if line.match?(/^## /)
      references = line.scan(/`((?:#{reference_roots.join("|")})\/[^`\s]+)`/).flatten
      references.concat(line.scan(/\]\(((?:#{reference_roots.join("|")})\/[^)\s]+)\)/).flatten)

      references.uniq.each do |relative|
        relative = relative.split(/[?#]/, 2).first
        next if relative.end_with?("/")
        next if relative.match?(/[{}*<>]/)

        root = relative.split("/", 2).first
        target = File.join(skill_dir, relative)
        generated_output = %w[scripts assets].include?(root) && (
          %w[생성\ 대상 출력 산출물].include?(current_heading) ||
          line.match?(/(생성|만들|추가|출력|산출|요청)/)
        )
        next if generated_output && !File.file?(target)

        errors << "#{name}: 참조 파일이 없습니다 - #{relative}" unless File.file?(target)
      end
    end
  end

  skill_content = File.read(skill_file)
  direct_references = (markdown_references(skill_content, reference_roots) + interface_references).uniq
  dynamic_component_references = direct_references.select do |reference|
    reference.start_with?("components/") && dynamic_reference?(reference)
  end
  dynamic_component_references.each do |reference|
    next if reference == "components/<component-name>.md"

    errors << "#{name}: 동적 컴포넌트 경로는 components/<component-name>.md 형식이어야 합니다 - #{reference}"
  end
  resource_files = orphan_roots.flat_map do |root|
    Dir.glob(File.join(skill_dir, root, "**", "*")).select { |path| File.file?(path) }
  end
  resource_files.sort.each do |resource_file|
    relative = resource_file.delete_prefix("#{skill_dir}/")
    next if direct_references.any? { |reference| reference_covers?(reference, relative) }

    errors << "#{name}: SKILL.md 또는 openai.yaml에 직접 연결되지 않은 보조 리소스입니다 - #{relative}"
  end

  if skill_content.include?("references/experts/{role}.md")
    expert_dir = File.join(skill_dir, "references", "experts")
    expert_files = Dir.glob(File.join(expert_dir, "*.md")).map { |path| File.basename(path, ".md") }.sort
    errors << "#{name}: 동적 expert role 파일이 없습니다" if expert_files.empty?

    selection_file = File.join(skill_dir, "references", "selection-rules.md")
    if File.file?(selection_file)
      candidate_roles = []
      in_candidates = false
      File.readlines(selection_file).each do |line|
        if line.strip == "## 후보군"
          in_candidates = true
          next
        end
        break if in_candidates && line.start_with?("## ")
        next unless in_candidates

        match = line.match(/^\|\s*([a-z0-9][a-z0-9-]*)\s*\|/)
        candidate_roles << match[1] if match
      end

      candidate_roles.uniq.each do |role|
        role_file = File.join(expert_dir, "#{role}.md")
        errors << "#{name}: expert role 파일이 없습니다 - #{role}.md" unless File.file?(role_file)
      end

      (expert_files - candidate_roles).each do |role|
        errors << "#{name}: 후보군에 없는 expert role 파일입니다 - #{role}.md"
      end
    else
      errors << "#{name}: 동적 expert role의 selection-rules.md가 없습니다"
    end
  end

  if direct_references.include?("components/<component-name>.md")
    component_dir = File.join(skill_dir, "components")
    component_files = Dir.glob(File.join(component_dir, "*.md")).map { |path| File.basename(path, ".md") }.sort
    listed_components = []
    in_component_list = false

    File.readlines(skill_file).each do |line|
      if line.strip == "## 컴포넌트 목록 출력"
        in_component_list = true
        next
      end
      break if in_component_list && line.start_with?("## ")
      next unless in_component_list

      match = line.match(/^-\s+`([a-z0-9][a-z0-9-]*)`:/)
      listed_components << match[1] if match
    end

    listed_components.uniq.each do |component|
      component_file = File.join(component_dir, "#{component}.md")
      errors << "#{name}: 컴포넌트 문서가 없습니다 - #{component}.md" unless File.file?(component_file)
    end

    (component_files - listed_components).each do |component|
      errors << "#{name}: 허용 목록에 없는 컴포넌트 문서입니다 - #{component}.md"
    end
  end

  if against_ref && repository_root
    skill_relative = Pathname.new(File.realpath(skill_file))
                             .relative_path_from(Pathname.new(File.realpath(repository_root)))
                             .to_s
    previous_skill, _stderr, previous_status = Open3.capture3(
      "git", "-C", repository_root, "show", "#{against_ref}:#{skill_relative}"
    )

    if previous_status.success?
      begin
        previous_metadata = frontmatter_content(previous_skill)
        current_metadata = frontmatter_content(skill_content)
        if previous_metadata["description"] != current_metadata["description"]
          contract_changes << "#{name}: description"
        end

        previous_sections = contract_sections(previous_skill)
        current_sections = contract_sections(skill_content)
        (previous_sections.keys | current_sections.keys).sort.each do |heading|
          next if previous_sections[heading] == current_sections[heading]

          contract_changes << "#{name}: ## #{heading}"
        end
      rescue StandardError => e
        errors << "#{name}: #{against_ref} 계약 비교 실패 - #{e.message}"
      end

      if File.file?(openai_file)
        openai_relative = Pathname.new(File.realpath(openai_file))
                                  .relative_path_from(Pathname.new(File.realpath(repository_root)))
                                  .to_s
        previous_openai, _openai_stderr, previous_openai_status = Open3.capture3(
          "git", "-C", repository_root, "show", "#{against_ref}:#{openai_relative}"
        )
        if previous_openai_status.success?
          begin
            previous_openai_data = YAML.safe_load(previous_openai) || {}
            current_openai_data = YAML.safe_load(File.read(openai_file)) || {}
            previous_interface = previous_openai_data["interface"].is_a?(Hash) ? previous_openai_data["interface"] : {}
            current_interface = current_openai_data["interface"].is_a?(Hash) ? current_openai_data["interface"] : {}
            %w[display_name short_description default_prompt].each do |field|
              next if previous_interface[field] == current_interface[field]

              contract_changes << "#{name}: interface.#{field}"
            end

            previous_policy = previous_openai_data.dig("policy", "allow_implicit_invocation")
            current_policy = current_openai_data.dig("policy", "allow_implicit_invocation")
            if previous_policy != current_policy
              contract_changes << "#{name}: policy.allow_implicit_invocation"
            end
          rescue StandardError => e
            errors << "#{name}: #{against_ref} openai.yaml 계약 비교 실패 - #{e.message}"
          end
        else
          contract_changes << "#{name}: agents/openai.yaml 신규"
        end
      end
    else
      contract_changes << "#{name}: #{against_ref}에 없는 신규 스킬"
    end
  end

  if check_tracked && repository_root
    Dir.glob(File.join(skill_dir, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }.sort.each do |path|
      relative = Pathname.new(File.realpath(path))
                         .relative_path_from(Pathname.new(File.realpath(repository_root)))
                         .to_s
      _stdout, _stderr, status = Open3.capture3(
        "git", "-C", repository_root, "ls-files", "--error-unmatch", "--", relative
      )
      errors << "#{name}: Git에 추적되지 않은 파일입니다 - #{relative}" unless status.success?
    end
  end
end

Dir.glob(File.join(skills_root, "ct-*", "**", "*.md")).sort.each do |path|
  content = File.read(path)
  visible_content = without_fenced_code(content)
  headings = visible_content.lines.grep(/^## /).map(&:strip)
  errors << "#{path}: 마지막 2단계 제목은 ## 이력관리여야 합니다" unless headings.last == "## 이력관리"

  history_index = visible_content.lines.rindex { |line| line.strip == "## 이력관리" }
  if history_index
    history_lines = visible_content.lines[(history_index + 1)..].reject { |line| line.strip.empty? }
    history_lines.each do |line|
      unless line.match?(/^- \d{4}-\d{2}-\d{2}: \S/)
        errors << "#{path}: 이력 항목은 - YYYY-MM-DD: 변경 내용 형식이어야 합니다"
        break
      end
    end
    history_dates = history_lines.filter_map { |line| line[/^- (\d{4}-\d{2}-\d{2}):/, 1] }
    duplicate_dates = history_dates.tally.select { |_date, count| count > 1 }.keys
    duplicate_dates.each { |date| errors << "#{path}: 같은 날짜의 이력 항목이 중복됩니다 - #{date}" }
  end

  next if File.basename(path) == "SKILL.md"
  next unless content.lines.length > 100

  opening = visible_content.lines.first(40).join
  errors << "#{path}: 100줄 초과 문서에는 상단 구성 또는 목차가 필요합니다" unless opening.match?(/^## (구성|목차)$/)
end


errors.uniq!
contract_changes.uniq.sort.each { |change| puts "CONTRACT_CHANGE #{change}" }
if fail_on_contract_change && contract_changes.any?
  errors << "#{against_ref} 대비 계약 변경이 있습니다 - #{contract_changes.length}건"
end

if errors.empty?
  puts "CT_SKILLS_OK"
  exit 0
end

errors.each { |error| warn "FAIL #{error}" }
warn "CT_SKILLS_FAIL=#{errors.length}"
exit 1
