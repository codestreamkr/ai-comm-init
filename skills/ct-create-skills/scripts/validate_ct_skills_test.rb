#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class ValidateCtSkillsTest < Minitest::Test
  VALIDATOR = File.expand_path("validate_ct_skills.rb", __dir__)

  def with_skills_root(body:, files: {})
    Dir.mktmpdir do |root|
      skill_dir = File.join(root, "ct-sample")
      write_file(
        File.join(skill_dir, "SKILL.md"),
        <<~MARKDOWN
          ---
          name: ct-sample
          description: CT 스킬 검증기의 회귀 동작을 확인한다.
          ---

          # CT Sample

          #{body}

          ## 이력관리

          - 2026-07-13: 회귀 검증용 fixture를 구성했다.
        MARKDOWN
      )
      write_file(
        File.join(skill_dir, "agents", "openai.yaml"),
        <<~YAML
          interface:
            display_name: "ct-sample"
            short_description: "CT 스킬 구조와 참조 관계의 회귀 동작을 검증합니다"
            default_prompt: "Use $ct-sample to validate this fixture."
          policy:
            allow_implicit_invocation: false
        YAML
      )
      files.each { |relative, content| write_file(File.join(skill_dir, relative), content) }
      yield root
    end
  end

  def test_directory_notation_is_not_treated_as_a_missing_file
    with_skills_root(body: "확장 후보는 `references/workflows/`에서 관리한다.") do |root|
      output, status = run_validator(root)

      assert status.success?, output
      assert_includes output, "CT_SKILLS_OK"
    end
  end

  def test_markdown_table_separator_is_not_treated_as_an_expert_role
    body = <<~MARKDOWN
      `references/selection-rules.md`를 읽는다.
      선택한 `references/experts/{role}.md`를 읽는다.
    MARKDOWN
    files = {
      "references/selection-rules.md" => <<~MARKDOWN,
        # 선정 기준

        ## 후보군

        | 역할 | 적용 기준 |
        |--------|--------|
        | backend | 서버 설계 |

        ## 이력관리

        - 2026-07-13: 후보군을 정리했다.
      MARKDOWN
      "references/experts/backend.md" => reference_document("Backend 기준")
    }

    with_skills_root(body: body, files: files) do |root|
      output, status = run_validator(root)

      assert status.success?, output
      refute_includes output, "--------.md"
    end
  end

  def test_legacy_document_roots_and_dynamic_component_link_are_supported
    body = <<~MARKDOWN
      `templates/output.md`를 출력에 사용한다.
      `workflow/run.md`를 실행 전에 읽는다.
      선택한 `components/<component-name>.md`를 읽는다.

      ## 컴포넌트 목록 출력

      - `api`: API 컴포넌트
    MARKDOWN
    files = {
      "templates/output.md" => reference_document("출력 템플릿"),
      "workflow/run.md" => reference_document("실행 절차"),
      "components/api.md" => reference_document("API 컴포넌트")
    }

    with_skills_root(body: body, files: files) do |root|
      output, status = run_validator(root)

      assert status.success?, output
    end
  end

  def test_component_list_requires_matching_document
    body = <<~MARKDOWN
      선택한 `components/<component-name>.md`를 읽는다.

      ## 컴포넌트 목록 출력

      - `missing`: 문서가 없는 컴포넌트
    MARKDOWN

    with_skills_root(body: body) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "컴포넌트 문서가 없습니다 - missing.md"
    end
  end

  def test_component_document_must_be_in_allowlist
    body = <<~MARKDOWN
      선택한 `components/<component-name>.md`를 읽는다.

      ## 컴포넌트 목록 출력

      허용 컴포넌트가 아직 없다.
    MARKDOWN
    files = { "components/extra.md" => reference_document("추가 컴포넌트") }

    with_skills_root(body: body, files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "허용 목록에 없는 컴포넌트 문서입니다 - extra.md"
    end
  end

  def test_unlinked_document_is_reported_as_an_orphan
    files = { "references/orphan.md" => reference_document("고립 문서") }

    with_skills_root(body: "별도 참조 없이 실행한다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "SKILL.md 또는 openai.yaml에 직접 연결되지 않은 보조 리소스입니다 - references/orphan.md"
    end
  end

  def test_missing_direct_reference_is_reported
    with_skills_root(body: "`templates/missing.md`를 출력에 사용한다.") do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "참조 파일이 없습니다 - templates/missing.md"
    end
  end

  def test_missing_script_reference_with_action_is_reported
    with_skills_root(body: "`scripts/missing.rb`를 실행한다.") do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "참조 파일이 없습니다 - scripts/missing.rb"
    end
  end

  def test_missing_script_and_asset_references_are_reported_without_action_words
    body = <<~MARKDOWN
      - 스크립트 경로: `scripts/missing.rb`
      - 템플릿 경로: `assets/missing.txt`
    MARKDOWN

    with_skills_root(body: body) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "참조 파일이 없습니다 - scripts/missing.rb"
      assert_includes output, "참조 파일이 없습니다 - assets/missing.txt"
    end
  end

  def test_generated_script_output_path_is_not_treated_as_bundled_resource
    body = <<~MARKDOWN
      ## 생성 대상

      - `scripts/local.sh`
    MARKDOWN

    with_skills_root(body: body) do |root|
      output, status = run_validator(root)

      assert status.success?, output
      assert_includes output, "CT_SKILLS_OK"
    end
  end

  def test_reference_inside_fenced_code_is_ignored
    body = <<~MARKDOWN
      ```text
      `references/missing.md`
      ```
    MARKDOWN

    with_skills_root(body: body) do |root|
      output, status = run_validator(root)

      assert status.success?, output
      assert_includes output, "CT_SKILLS_OK"
    end
  end

  def test_reference_inside_fenced_code_does_not_connect_orphan
    body = <<~MARKDOWN
      ```text
      `references/orphan.md`
      ```
    MARKDOWN
    files = { "references/orphan.md" => reference_document("고립 문서") }

    with_skills_root(body: body, files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "직접 연결되지 않은 보조 리소스입니다 - references/orphan.md"
    end
  end

  def test_unlinked_script_is_reported_as_an_orphan
    files = { "scripts/orphan.rb" => "puts 'orphan'\n" }

    with_skills_root(body: "별도 스크립트 없이 실행한다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "SKILL.md 또는 openai.yaml에 직접 연결되지 않은 보조 리소스입니다 - scripts/orphan.rb"
    end
  end

  def test_history_heading_inside_fenced_code_does_not_satisfy_document_rule
    files = {
      "references/fenced.md" => <<~MARKDOWN
        # 코드 블록 이력

        ```markdown
        ## 이력관리
        ```
      MARKDOWN
    }

    with_skills_root(body: "`references/fenced.md`를 읽는다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "references/fenced.md: 마지막 2단계 제목은 ## 이력관리여야 합니다"
    end
  end

  def test_dynamic_component_requires_canonical_path_notation
    body = <<~MARKDOWN
      선택한 `components/{component}.md`를 읽는다.

      ## 컴포넌트 목록 출력

      - `api`: API 컴포넌트
    MARKDOWN
    files = { "components/api.md" => reference_document("API 컴포넌트") }

    with_skills_root(body: body, files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "동적 컴포넌트 경로는 components/<component-name>.md 형식이어야 합니다"
    end
  end

  def test_agents_directory_rejects_files_other_than_openai_yaml
    files = { "agents/helper.md" => reference_document("추가 에이전트") }

    with_skills_root(body: "추가 에이전트 없이 실행한다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "agents에는 openai.yaml만 둘 수 있습니다 - agents/helper.md"
    end
  end

  def test_history_heading_inside_nested_fence_does_not_leak_from_outer_fence
    files = {
      "references/nested-fence.md" => <<~MARKDOWN
        # 중첩 코드 fence

        ````markdown
        # 생성 문서 예시

        ```text
        ## 이력관리
        ```
        ````
      MARKDOWN
    }

    with_skills_root(body: "`references/nested-fence.md`를 읽는다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "references/nested-fence.md: 마지막 2단계 제목은 ## 이력관리여야 합니다"
    end
  end

  def test_invalid_history_item_format_is_reported
    files = {
      "references/history.md" => <<~MARKDOWN
        # 이력 형식

        ## 이력관리

        - 형식이 잘못된 이력
      MARKDOWN
    }

    with_skills_root(body: "`references/history.md`를 읽는다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "이력 항목은 - YYYY-MM-DD: 변경 내용 형식이어야 합니다"
    end
  end

  def test_duplicate_history_date_is_reported
    files = {
      "references/history.md" => <<~MARKDOWN
        # 이력 중복

        ## 이력관리

        - 2026-07-13: 첫 변경
        - 2026-07-13: 두 번째 변경
      MARKDOWN
    }

    with_skills_root(body: "`references/history.md`를 읽는다.", files: files) do |root|
      output, status = run_validator(root)

      refute status.success?, output
      assert_includes output, "같은 날짜의 이력 항목이 중복됩니다 - 2026-07-13"
    end
  end

  def test_against_reports_contract_change_without_failing
    with_skills_root(body: "## 입력\n\n- 기본 계약으로 실행한다.") do |root|
      run_command("git", "init", "-q", root)
      run_command("git", "-C", root, "add", ".")
      run_command(
        "git", "-C", root,
        "-c", "user.name=CT Validator", "-c", "user.email=ct@example.com",
        "commit", "-qm", "baseline"
      )

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("기본 계약으로 실행한다.", "변경된 계약으로 실행한다.")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample:"
      assert_includes output, "CT_SKILLS_OK"
    end
  end

  def test_against_detects_completion_contract_change
    with_skills_root(body: "## 완료 조건\n\n- 필수 계약을 확인한다.") do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("필수 계약을 확인한다.", "변경 계약을 확인한다.")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample: ## 완료 조건"
    end
  end

  def test_against_detects_change_in_any_h2_contract_section
    with_skills_root(body: "## 작업 절차\n\n- 기존 절차로 실행한다.") do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("기존 절차로 실행한다.", "변경 절차로 실행한다.")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample: ## 작업 절차"
    end
  end

  def test_against_ignores_change_inside_fenced_code
    body = <<~MARKDOWN
      ## 작업 절차

      ```text
      기존 예시
      ```
    MARKDOWN

    with_skills_root(body: body) do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("기존 예시", "변경 예시")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      refute_includes output, "CONTRACT_CHANGE"
    end
  end

  def test_against_excludes_history_section_from_contract_changes
    with_skills_root(body: "## 작업 절차\n\n- 기본 절차로 실행한다.") do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("회귀 검증용 fixture를 구성했다.", "회귀 검증 이력을 갱신했다.")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      refute_includes output, "CONTRACT_CHANGE"
    end
  end

  def test_against_detects_openai_interface_and_policy_changes
    with_skills_root(body: "기본 계약으로 실행한다.") do |root|
      commit_fixture(root)

      openai_file = File.join(root, "ct-sample", "agents", "openai.yaml")
      updated = File.read(openai_file)
                    .sub('display_name: "ct-sample"', 'display_name: "CT Sample"')
                    .sub("CT 스킬 구조와 참조 관계의 회귀 동작을 검증합니다", "CT 스킬의 변경된 표시 정보와 호출 계약을 회귀 검증합니다")
                    .sub("Use $ct-sample to validate this fixture.", "Use $ct-sample to validate the changed fixture.")
                    .sub("allow_implicit_invocation: false", "allow_implicit_invocation: true")
      File.write(openai_file, updated)

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample: interface.display_name"
      assert_includes output, "CONTRACT_CHANGE ct-sample: interface.short_description"
      assert_includes output, "CONTRACT_CHANGE ct-sample: interface.default_prompt"
      assert_includes output, "CONTRACT_CHANGE ct-sample: policy.allow_implicit_invocation"
    end
  end

  def test_against_does_not_run_tracked_check
    with_skills_root(body: "## 작업 절차\n\n- 기본 절차로 실행한다.") do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub(
        "- 기본 절차로 실행한다.",
        "- 변경 절차로 실행한다.\n- `references/new.md`를 읽는다."
      )
      File.write(skill_file, updated)
      write_file(File.join(root, "ct-sample", "references", "new.md"), reference_document("신규 문서"))

      output, status = run_validator(root, "--against", "HEAD")

      assert status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample: ## 작업 절차"
      refute_includes output, "Git에 추적되지 않은 파일입니다"
    end
  end

  def test_fail_on_contract_change_requires_against
    with_skills_root(body: "기본 계약으로 실행한다.") do |root|
      output, status = run_validator(root, "--fail-on-contract-change")

      refute status.success?, output
      assert_includes output, "--fail-on-contract-change는 --against <Git ref>와 함께 사용해야 합니다"
    end
  end

  def test_fail_on_contract_change_returns_failure
    with_skills_root(body: "## 출력 형식\n\n- 기본 형식으로 출력한다.") do |root|
      commit_fixture(root)

      skill_file = File.join(root, "ct-sample", "SKILL.md")
      updated = File.read(skill_file).sub("기본 형식으로 출력한다.", "변경 형식으로 출력한다.")
      File.write(skill_file, updated)

      output, status = run_validator(root, "--against", "HEAD", "--fail-on-contract-change")

      refute status.success?, output
      assert_includes output, "CONTRACT_CHANGE ct-sample: ## 출력 형식"
      assert_includes output, "HEAD 대비 계약 변경이 있습니다"
    end
  end

  def test_tracked_mode_reports_untracked_skill_resource
    files = { "references/tracked.md" => reference_document("추적 검사") }

    with_skills_root(body: "`references/tracked.md`를 읽는다.", files: files) do |root|
      run_command("git", "init", "-q", root)
      run_command("git", "-C", root, "add", "ct-sample/SKILL.md", "ct-sample/agents/openai.yaml")

      output, status = run_validator(root, "--tracked")

      refute status.success?, output
      assert_includes output, "Git에 추적되지 않은 파일입니다 - ct-sample/references/tracked.md"
    end
  end

  private

  def commit_fixture(root)
    run_command("git", "init", "-q", root)
    run_command("git", "-C", root, "add", ".")
    run_command(
      "git", "-C", root,
      "-c", "user.name=CT Validator", "-c", "user.email=ct@example.com",
      "commit", "-qm", "baseline"
    )
  end

  def run_validator(root, *args)
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, VALIDATOR, *args, root)
    [stdout + stderr, status]
  end

  def run_command(*command)
    stdout, stderr, status = Open3.capture3(*command)
    assert status.success?, stdout + stderr
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def reference_document(title)
    <<~MARKDOWN
      # #{title}

      검증에 사용하는 문서다.

      ## 이력관리

      - 2026-07-13: 회귀 검증용 문서를 구성했다.
    MARKDOWN
  end
end
