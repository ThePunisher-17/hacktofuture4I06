import os
import django
from datetime import timedelta
from django.utils import timezone
import random

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from django.contrib.auth import get_user_model
from accounts.models import Organization, OrganizationMember, Role, UserProfile
from integrations.models import Integration
from tickets.models import UnifiedTicket, ExternalIdentity
from insights.models import Insight

User = get_user_model()

print("Starting to seed database...")

# Get or create Org
org, _ = Organization.objects.get_or_create(
    name="Acme Corp Demo",
    slug="acme-corp-demo",
    defaults={"is_active": True, "plan_tier": "pro"}
)

# Get or create User
user, _ = User.objects.get_or_create(
    email="demo@acme.com",
    username="demo@acme.com",
    defaults={"first_name": "Demo", "last_name": "User"}
)
if not user.has_usable_password():
    user.set_password("DemoPassword123!")
    user.save()

# Profile
UserProfile.objects.get_or_create(user=user, defaults={"organization": org, "is_onboarded": True})

# Member
role, _ = Role.objects.get_or_create(name="owner", is_system=True)
OrganizationMember.objects.get_or_create(organization=org, user=user, defaults={"role": role})

# Integration
jira_int, _ = Integration.objects.get_or_create(
    organization=org,
    provider="jira",
    defaults={
        "name": "Jira Production",
        "is_active": True
    }
)

slack_int, _ = Integration.objects.get_or_create(
    organization=org,
    provider="slack",
    defaults={
        "name": "Slack Engineering",
        "is_active": True
    }
)

# External Identity
ext_identity, _ = ExternalIdentity.objects.get_or_create(
    organization=org,
    integration=jira_int,
    external_user_id="user_123",
    defaults={
        "display_name": "Jane Developer",
        "email": "jane@acme.com",
        "user": user
    }
)

# Tickets
ticket_data = [
    {"ext_id": "ENG-101", "title": "Fix database serialization rounding bug natively", "status": "open", "type": "bug", "priority": "high"},
    {"ext_id": "ENG-102", "title": "Implement WebSockets for Chat", "status": "in_progress", "type": "feature", "priority": "medium"},
    {"ext_id": "ENG-103", "title": "Refactor React hooks component state", "status": "resolved", "type": "task", "priority": "low"},
    {"ext_id": "ENG-104", "title": "Investigate memory leak in Celery workers", "status": "blocked", "type": "bug", "priority": "critical"},
    {"ext_id": "ENG-105", "title": "Upgrade PostgreSQL to v14", "status": "open", "type": "task", "priority": "medium"},
    {"ext_id": "ENG-106", "title": "Redesign Operator Dashboard UI", "status": "in_progress", "type": "story", "priority": "medium"},
    {"ext_id": "ENG-107", "title": "Document LangGraph workflow nodes", "status": "resolved", "type": "task", "priority": "low"},
]

for dt in ticket_data:
    UnifiedTicket.objects.update_or_create(
        organization=org,
        integration=jira_int,
        external_ticket_id=dt["ext_id"],
        defaults={
            "title": dt["title"],
            "normalized_status": dt["status"],
            "normalized_type": dt["type"],
            "priority": dt["priority"],
            "assignee": ext_identity,
            "source_created_at": timezone.now() - timedelta(days=random.randint(1, 14)),
            "source_updated_at": timezone.now() - timedelta(hours=random.randint(1, 48)),
        }
    )

print("")
print("✅ Data seeded successfully!")
print("✨ You can log in using:")
print("   Email: demo@acme.com")
print("   Password: DemoPassword123!")
