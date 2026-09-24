# 1. 네임스페이스 생성
resource "kubernetes_namespace" "whatap" {
  metadata { name = "whatap-monitoring" }
}

# 2. 자격증명 시크릿
resource "kubernetes_secret" "whatap_credentials" {
  metadata {
    name      = "whatap-credentials"
    namespace = kubernetes_namespace.whatap.metadata[0].name
  }
  data = {
    WHATAP_LICENSE = var.whatap_license
    WHATAP_HOST    = "13.124.11.223/13.209.172.35"
    WHATAP_PORT    = "6600"
  }
}

# 3. 와탭 오퍼레이터 설치 (Helm)
resource "helm_release" "whatap_operator" {
  name       = "whatap-operator"
  repository = "https://whatap.github.io/helm"
  chart      = "whatap-operator"
  namespace  = kubernetes_namespace.whatap.metadata[0].name
  depends_on = [kubernetes_namespace.whatap]
}

# 💡 4. kubectl_manifest를 통한 무검증 다이렉트 주입 (자동화 핵심)
resource "kubectl_manifest" "whatap_agent" {
  yaml_body = <<YAML
apiVersion: "monitoring.whatap.com/v2alpha1"
kind: "WhatapAgent"
metadata:
  labels:
    app.kubernetes.io/managed-by: "whatap-operator"
    app.kubernetes.io/name: "whatap"
  name: "whatap"
  namespace: "whatap-monitoring"
spec:
  secretName: "whatap-credentials"
  features:
    k8sAgent:
      customAgentImageFullName: "public.ecr.aws/whatap/kube_mon:1.8.7"
      gpuMonitoring:
        enabled: false
      masterAgent:
        enabled: true
      nodeAgent:
        enabled: true
        runtime: "containerd"
        runtimeSocketPath: "/var/run/containerd/containerd.sock"
YAML

  # 헬름 오퍼레이터가 완벽히 안착한 후 배포되도록 강제 보장
  depends_on = [helm_release.whatap_operator]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = module.workload.cluster_name
  addon_name   = "amazon-cloudwatch-observability"

  depends_on = [
    module.workload
  ]

  tags = merge(local.common_tags, {
    Name = "${module.workload.cluster_name}-cloudwatch-observability"
  })
}

resource "aws_cloudwatch_dashboard" "integrated_monitoring_dashboard" {
  dashboard_name = "${module.workload.cluster_name}-Integrated-Operations-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ============================================================
      # [PAGE 1 - 종합 서비스 헬스케어 & 관제 레이어 (y=0)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/Route53,HealthCheckId} MetricName=\"HealthCheckStatus\"', 'Average', 60)", "label" : "DNS: &&-SCHEMA-REPLACEMENT-&&", "id" : "dns1", "region" : "us-east-1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "DNS (Route 53) Health Check Status (1=Healthy, 0=Unhealthy)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_2XX_Count\"', 'Sum', 60)", "label" : "2XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb2xx", "color" : "#2ca02c" }],
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_4XX_Count\"', 'Sum', 60)", "label" : "4XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb4xx", "color" : "#ff7f0e" }],
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)", "label" : "5XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb5xx", "color" : "#d62728" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "ALB Target Response Code Distribution (2XX/4XX/5XX)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"cluster_failed_node_count\"', 'Maximum', 60)", "label" : "Failed Nodes", "id" : "k8sfail", "color" : "#ff7f0e" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "EKS Cluster Failed Node Count (Cluster Health)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 2 - Ingress ALB & EKS 인프라 레이어 (y=6)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"HealthyHostCount\"', 'Average', 60)", "label" : "🟢 Healthy: &&-SCHEMA-REPLACEMENT-&&", "id" : "h1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Ingress Auto-Generated Targets: Healthy Host Count"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Average', 60)", "label" : "🔴 UnHealthy: &&-SCHEMA-REPLACEMENT-&&", "id" : "uh1", "color" : "#d62728" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Ingress Auto-Generated Targets: UnHealthy Host Count"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 60)", "label" : "Requests: &&-SCHEMA-REPLACEMENT-&&", "id" : "req1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Ingress ALB Total Request Count (Traffic Rate)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"TargetResponseTime\"', 'Average', 60)", "label" : "Latency: &&-SCHEMA-REPLACEMENT-&&", "id" : "latency1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Target Response Time per Auto-Generated Ingress Group (Average)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_cpu_utilization\"', 'Average', 60)", "label" : "Node CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "ncpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "EKS Worker Nodes CPU Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_memory_utilization\"', 'Average', 60)", "label" : "Node Mem: &&-SCHEMA-REPLACEMENT-&&", "id" : "nmem" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "EKS Worker Nodes Memory Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 24
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_number_of_container_restarts\"', 'Sum', 60)", "label" : "Restart Count: &&-SCHEMA-REPLACEMENT-&&", "id" : "podrest", "color" : "#1f77b4" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "EKS Pod Container Restart Count (Detecting CrashLoopBackOff)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 3 - 애플리케이션 성능 및 DB 레이어 (y=30)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_cpu_utilization\"', 'Average', 60)", "label" : "Pod CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "pcpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Application Pods CPU Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_memory_utilization\"', 'Average', 60)", "label" : "Pod Mem: &&-SCHEMA-REPLACEMENT-&&", "id" : "pmem" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Application Pods Memory Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"CPUUtilization\"', 'Average', 60)", "label" : "DB CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdscpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Database (RDS) CPU Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"DatabaseConnections\"', 'Average', 60)", "label" : "Connections: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsconn", "color" : "#9467bd" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "Database Connection Count (Connection Pool Monitor)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"ReplicationLag\"', 'Maximum', 60)", "label" : "Lag Sec: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdslag", "color" : "#e377c2" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "RDS Cross-Region Replication Lag (DR Metric)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 42
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 60) / 60", "label" : "TPS: &&-SCHEMA-REPLACEMENT-&&", "id" : "albtps" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "ALB Transactions Per Second"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 42
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceInstances\"', 'Average', 60)", "label" : "Running: &&-SCHEMA-REPLACEMENT-&&", "id" : "asgrun" }],
            [{ "expression" : "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupDesiredCapacity\"', 'Average', 60)", "label" : "Desired: &&-SCHEMA-REPLACEMENT-&&", "id" : "asgdes", "color" : "#9467bd" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "EKS Node Group (ASG) Desired vs Running Capacity"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 42
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"FreeableMemory\"', 'Average', 60)", "label" : "FreeMem: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsmem" }],
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"FreeStorageSpace\"', 'Average', 60)", "label" : "FreeDisk: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsdisk", "color" : "#8c564b" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "RDS Memory & Storage Headroom"
          view   = "timeSeries"
        }
      }
    ]
  })
}

data "aws_lb" "petclinic_ingress" {
  name       = regex("^(.+)-[0-9]+\\.ap-northeast-2\\.elb\\.amazonaws\\.com$", module.workload.ingress_dns_name)[0]
  depends_on = [module.workload]
}

# ==========================================
# 1. 알림 채널 구성 (SNS & Chatbot)
# ==========================================

# SNS 토픽 생성
# resource "aws_sns_topic" "rds_alarm_topic" {
#   name = "petclinic-rds-alarm-topic"
# }

# # 이메일 구독 설정 (테라폼 apply 후 메일함에서 'Confirm Subscription'을 눌러야 활성화됩니다)
# resource "aws_sns_topic_subscription" "email_subscription" {
#   # for_each를 사용하여 여러 명에게 구독 설정
#   for_each = toset(local.alarm_emails)

#   topic_arn = aws_sns_topic.rds_alarm_topic.arn
#   protocol  = "email"
#   endpoint  = each.value # 리스트의 이메일이 하나씩 매핑됩니다.
# }

# Slack 연동을 위한 AWS Chatbot 설정
# 주의: AWS Chatbot의 Workspace ID는 콘솔에서 최초 1회 Slack 인증을 진행해야 확인 가능합니다.
resource "aws_chatbot_slack_channel_configuration" "slack_alarm" {
  configuration_name = "route53_healthcheck-slack-alarm"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_channel_id   = "C0BB6V15RG9" # 알람을 보낼 슬랙 채널 ID 입력
  slack_team_id      = "T0BB1N1H97X" # AWS 콘솔에 연동된 슬랙 워크스페이스 ID 입력

  sns_topic_arns = [
    aws_sns_topic.route53_healthcheck_alarm.arn,
    aws_sns_topic.aws_primary_origin_healthcheck_alarm.arn,
    aws_sns_topic.cloudfront_5xx_alarm.arn,
    aws_sns_topic.operations_alarm.arn
  ]
}

# Chatbot을 위한 기본 IAM Role
resource "aws_iam_role" "chatbot_role" {
  name = "aws-chatbot-rds-alarm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "chatbot.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot_notification_policy" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess" # 알람 메트릭을 읽어올 수 있는 정책
}

resource "aws_sns_topic" "route53_healthcheck_alarm" {
  provider = aws.us_east_1
  name     = "${local.namespace}-route53-healthcheck-alarm"
}

resource "aws_sns_topic" "aws_primary_origin_healthcheck_alarm" {
  provider = aws.us_east_1
  name     = "${local.namespace}-aws-primary-origin-healthcheck-alarm"
}

resource "aws_sns_topic" "cloudfront_5xx_alarm" {
  provider = aws.us_east_1
  name     = "${local.namespace}-cloudfront-5xx-alarm"
}

resource "aws_sns_topic" "operations_alarm" {
  name = "${local.namespace}-operations-alarm"
}

# ==========================================
# 2. 지표별 CloudWatch Alarm 구성
# ==========================================

#라우트53 헬스체크 알람
resource "aws_cloudwatch_metric_alarm" "route53_healthcheck_unhealthy" {
  provider = aws.us_east_1

  alarm_name          = "${local.namespace}-route53-healthcheck-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60 # 1분
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = module.platform.route53_health_check_id
  }

  alarm_description = "Route 53 health check ${module.platform.route53_health_check_id} is unhealthy."

  alarm_actions             = [aws_sns_topic.route53_healthcheck_alarm.arn]
  ok_actions                = [aws_sns_topic.route53_healthcheck_alarm.arn]
  insufficient_data_actions = [aws_sns_topic.route53_healthcheck_alarm.arn]
}

# AWS primary origin(ALB) 헬스체크 알람. 이 알람이 DR 판단의 직접 신호다.
resource "aws_cloudwatch_metric_alarm" "aws_primary_origin_healthcheck_unhealthy" {
  provider = aws.us_east_1

  alarm_name          = "${local.namespace}-aws-primary-origin-healthcheck-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = module.platform.route53_health_check_id
  }

  alarm_description = "AWS primary origin health check ${module.platform.route53_health_check_id} is unhealthy."

  alarm_actions             = [aws_sns_topic.aws_primary_origin_healthcheck_alarm.arn]
  ok_actions                = [aws_sns_topic.aws_primary_origin_healthcheck_alarm.arn]
  insufficient_data_actions = [aws_sns_topic.aws_primary_origin_healthcheck_alarm.arn]
}

# CloudFront 5xx error rate alarm
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_error_rate_high" {
  provider = aws.us_east_1

  alarm_name          = "${local.namespace}-cloudfront-5xx-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 60 # 60 seconds
  statistic           = "Average"
  threshold           = 80 # 80%
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = module.platform.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_description = "CloudFront distribution ${module.platform.cloudfront_distribution_id} returned 5xx errors above 80% for 60 seconds."

  alarm_actions = [aws_sns_topic.cloudfront_5xx_alarm.arn]
  ok_actions    = [aws_sns_topic.cloudfront_5xx_alarm.arn]
}

# RDS Alarm - Replica Lag Alarm
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag_high" {
  alarm_name          = "${local.namespace}-rds-replica-lag-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = "petclinic-db-instance"
  }

  alarm_description = "RDS replica lag for petclinic-db-instance exceeded 300 seconds."
  alarm_actions     = [aws_sns_topic.operations_alarm.arn]
  ok_actions        = [aws_sns_topic.operations_alarm.arn]
}

# RDS Alarm - Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.namespace}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5GB (bytes 단위)  
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = "petclinic-db-instance"
  }

  alarm_description = "RDS free storage for petclinic-db-instance is below 5 GiB."
  alarm_actions     = [aws_sns_topic.operations_alarm.arn]
  ok_actions        = [aws_sns_topic.operations_alarm.arn]
}

# EKS Alarm - Pod Restarts Alarm
resource "aws_cloudwatch_metric_alarm" "eks_pod_restarts_high" {
  alarm_name          = "${local.namespace}-eks-pod-restarts-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "podrestarts"
    expression  = "SELECT SUM(pod_number_of_container_restarts) FROM SCHEMA(\"ContainerInsights\", ClusterName, Namespace, PodName, FullPodName) WHERE ClusterName = '${module.workload.cluster_name}' AND Namespace = 'petclinic'"
    label       = "Petclinic pod container restarts"
    period      = 300
    return_data = true
  }

  alarm_description = "Petclinic pods restarted more than 5 times in 5 minutes."
  alarm_actions     = [aws_sns_topic.operations_alarm.arn]
  ok_actions        = [aws_sns_topic.operations_alarm.arn]
}

# EKS Alarm - Failed Node Count Alarm
resource "aws_cloudwatch_metric_alarm" "eks_failed_node_count_high" {
  alarm_name          = "${local.namespace}-eks-failed-node-count-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.workload.cluster_name
  }

  alarm_description = "EKS cluster ${module.workload.cluster_name} has one or more failed nodes."
  alarm_actions     = [aws_sns_topic.operations_alarm.arn]
  ok_actions        = [aws_sns_topic.operations_alarm.arn]
}

# ALB Alarm - Target 5xx Responses Alarm
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx_high" {
  alarm_name          = "${local.namespace}-alb-target-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.petclinic_ingress.arn_suffix
  }

  alarm_description = "ALB ${data.aws_lb.petclinic_ingress.name} target 5xx responses exceeded 10 in 5 minutes."
  alarm_actions     = [aws_sns_topic.operations_alarm.arn]
  ok_actions        = [aws_sns_topic.operations_alarm.arn]
}

# ap-northeast-2 Region Healthcheck 관련
resource "aws_cloudwatch_log_group" "aws_health_to_slack" {
  name              = local.aws_health_to_slack_log_group
  retention_in_days = 30
}

resource "aws_iam_role" "aws_health_to_slack" {
  name = local.aws_health_to_slack_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "aws_health_to_slack_logs" {
  name = "CloudWatchLogsWrite"
  role = aws_iam_role.aws_health_to_slack.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.aws_health_to_slack.arn}:*"
    }]
  })
}

resource "aws_lambda_function" "aws_health_to_slack" {
  function_name    = local.aws_health_to_slack_name
  role             = aws_iam_role.aws_health_to_slack.arn
  handler          = "aws_health_to_slack.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.aws_health_to_slack.output_path
  source_code_hash = data.archive_file.aws_health_to_slack.output_base64sha256
  timeout          = 15
  memory_size      = 128
  architectures    = ["x86_64"]

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.aws_health_to_slack,
    aws_iam_role_policy.aws_health_to_slack_logs
  ]
}

resource "aws_cloudwatch_event_rule" "aws_health_to_slack" {
  name           = local.aws_health_to_slack_rule_name
  description    = "Capture AWS Health events and route them to the Slack notifier Lambda."
  event_bus_name = "default"
  event_pattern = jsonencode({
    source = ["aws.health"]
  })
}

resource "aws_cloudwatch_event_target" "aws_health_to_slack" {
  rule           = aws_cloudwatch_event_rule.aws_health_to_slack.name
  event_bus_name = aws_cloudwatch_event_rule.aws_health_to_slack.event_bus_name
  target_id      = "HealthToSlackTarget"
  arn            = aws_lambda_function.aws_health_to_slack.arn
}

resource "aws_lambda_permission" "aws_health_to_slack_events" {
  statement_id  = "aws-health-to-slack-seoul-HealthToSlackInvokePermission-FXhoqthNoWY3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_health_to_slack.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aws_health_to_slack.arn
}
