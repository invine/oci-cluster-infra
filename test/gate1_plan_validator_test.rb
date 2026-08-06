# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

class Gate1PlanValidatorTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  VALIDATOR = File.join(ROOT, "scripts", "validate-gate1-plan")
  FIXTURES = File.join(__dir__, "fixtures", "gate1")
  APPROVED_PLAN = JSON.parse(File.read(File.join(FIXTURES, "approved-plan.json")))
  SERVICE_EVIDENCE = File.join(FIXTURES, "service.json")
  FIXTURE_BIN = File.join(FIXTURES, "bin")

  def test_approved_gate_1_plan_passes
    status, stdout, stderr = run_validator(APPROVED_PLAN)

    assert_predicate status, :success?, stderr
    assert_equal "PASS: Gate 1 plan fc5ebdd9683220895bf7162fa69f0f965b016b6a6e543442b17a46de047dda71\n", stdout
    assert_empty stderr
  end

  def test_approved_gate_1_plan_passes_with_a_single_service_capture
    service = JSON.parse(File.read(SERVICE_EVIDENCE)).fetch("items").fetch(0)

    status, _stdout, stderr = run_validator(APPROVED_PLAN, service: service)

    assert_predicate status, :success?, stderr
  end

  def test_meaningful_kubeconfig_change_fails_without_exposing_content
    plan = deep_copy(APPROVED_PLAN)
    kubeconfig_change(plan)["after"]["content"] = kubeconfig_change(plan)["after"]["content"].sub(
      "https://api.example.invalid:6443",
      "https://changed.example.invalid:6443"
    )

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: kubeconfig changed beyond aliases\n", stderr
    refute_includes stderr, "changed.example.invalid"
  end

  def test_kubeconfig_user_name_is_not_an_allowed_alias
    plan = deep_copy(APPROVED_PLAN)
    after_content = kubeconfig_change(plan).fetch("after").fetch("content")
    kubeconfig_change(plan)["after"]["content"] = after_content
      .sub("name: user-fixture", "name: changed-user")
      .sub("user: user-fixture", "user: changed-user")

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: kubeconfig changed beyond aliases\n", stderr
  end

  def test_retained_worker_pool_identity_change_fails_without_exposing_identity
    plan = deep_copy(APPROVED_PLAN)
    worker_change(plan)["after"]["id"] = "ocid1.nodepool.example.changed"

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: retained worker pool changed\n", stderr
    refute_includes stderr, "ocid1.nodepool.example.changed"
  end

  def test_non_allowlisted_security_rule_change_fails_without_exposing_rule_values
    plan = deep_copy(APPROVED_PLAN)
    security_change(plan, "oci_core_security_list.private-security-list")["after"]["ingress_security_rules"] = []

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: security list changed outside captured redundant rules\n", stderr
    refute_includes stderr, "0.0.0.0/0"
  end

  def test_any_still_present_subset_of_captured_service_rules_is_accepted
    plan = deep_copy(APPROVED_PLAN)
    private_change = security_change(plan, "oci_core_security_list.private-security-list")
    public_change = security_change(plan, "oci_core_security_list.public-security-list")
    private_change["after"]["ingress_security_rules"] << private_change["before"]["ingress_security_rules"].fetch(1)
    public_change["after"]["egress_security_rules"] << public_change["before"]["egress_security_rules"].fetch(1)

    status, _stdout, stderr = run_validator(plan)

    assert_predicate status, :success?, stderr
  end

  def test_kubeconfig_output_mode_must_be_0600
    plan = deep_copy(APPROVED_PLAN)
    kubeconfig_change(plan)["after"]["file_permission"] = "0644"

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: kubeconfig file contract changed\n", stderr
  end

  def test_unrelated_resource_action_fails_without_exposing_resource_values
    plan = deep_copy(APPROVED_PLAN)
    cluster = plan.fetch("resource_changes").find do |change|
      change.fetch("address") == "oci_containerengine_cluster.k8s_cluster"
    end
    cluster.fetch("change")["actions"] = ["update"]
    cluster.fetch("change")["after"]["id"] = "changed-cluster"

    status, stdout, stderr = run_validator(plan)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: plan contains an unrelated resource action\n", stderr
    refute_includes stderr, "changed-cluster"
  end

  def test_changed_ingress_service_contract_fails
    service = JSON.parse(File.read(SERVICE_EVIDENCE))
    service.fetch("items").fetch(0).fetch("spec").fetch("ports").fetch(0)["port"] = 8080

    status, stdout, stderr = run_validator(APPROVED_PLAN, service: service)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: captured ingress Service ports are invalid\n", stderr
  end

  def test_unreadable_artifact_fails_without_exposing_its_path
    missing_plan = "/private/example/sensitive-plan-name.tfplan"
    stdout, stderr, status = Open3.capture3(
      VALIDATOR,
      "--plan",
      missing_plan,
      "--service-evidence",
      SERVICE_EVIDENCE
    )

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: unable to read required local artifact\n", stderr
    refute_includes stderr, missing_plan
  end

  def test_invalid_arguments_fail_without_exposing_their_value
    sensitive_argument = "private-sensitive-value"
    stdout, stderr, status = Open3.capture3(VALIDATOR, "--unknown", sensitive_argument)

    refute_predicate status, :success?
    assert_empty stdout
    assert_equal "FAIL: invalid command arguments\n", stderr
    refute_includes stderr, sensitive_argument
  end

  private

  def deep_copy(value)
    JSON.parse(JSON.generate(value))
  end

  def kubeconfig_change(plan)
    plan.fetch("resource_changes").find do |change|
      change.fetch("address") == "local_file.k8s_cluster_kube_config_file"
    end.fetch("change")
  end

  def worker_change(plan)
    plan.fetch("resource_changes").find do |change|
      change.fetch("address") == "oci_containerengine_node_pool.worker_pool[\"v1.34.2\"]"
    end.fetch("change")
  end

  def security_change(plan, address)
    plan.fetch("resource_changes").find do |change|
      change.fetch("address") == address
    end.fetch("change")
  end

  def run_validator(plan, service: nil)
    Dir.mktmpdir("gate1-validator-test") do |directory|
      plan_json = File.join(directory, "plan.json")
      saved_plan = File.join(directory, "plan.tfplan")
      service_evidence = SERVICE_EVIDENCE
      File.write(plan_json, JSON.generate(plan))
      File.write(saved_plan, "non-sensitive saved plan fixture")
      if service
        service_evidence = File.join(directory, "service.json")
        File.write(service_evidence, JSON.generate(service))
      end

      env = {
        "GATE1_PLAN_JSON_FIXTURE" => plan_json,
        "PATH" => "#{FIXTURE_BIN}:#{ENV.fetch("PATH")}"
      }
      stdout, stderr, status = Open3.capture3(
        env,
        VALIDATOR,
        "--plan",
        saved_plan,
        "--service-evidence",
        service_evidence
      )
      [status, stdout, stderr]
    end
  end
end
