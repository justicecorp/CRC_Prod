## Web ACL: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
resource "aws_wafv2_web_acl" "apigwwebacl" {
  name        = "APIGWwebacl"
  description = "WebACL for APIGW - all AWS managed rules"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "managed-IPReputation-rule"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-IPREP-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-BotControl-rule"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }

        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-BOT-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  rule {
    name     = "managed-common-rule"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIGW-WEBACL-COMMON-METRIC"
      sampled_requests_enabled   = true
    }
    override_action {
      none {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "APIGW-WEBACL-METRIC"
    sampled_requests_enabled   = true
  }
}