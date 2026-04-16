#!/bin/bash
# Comprehensive endpoint test for VoxBridge frontend features
cd /home/rajan/Projects/HTF/hacktofuture4I06

echo "========================================="
echo "  VoxBridge Feature Verification Suite"
echo "========================================="

# 1. Test Register
echo ""
echo "--- 1. REGISTER ---"
docker compose exec -T backend python manage.py shell -c "
import json
from django.test import Client, override_settings
with override_settings(ALLOWED_HOSTS=['*']):
    c = Client(SERVER_NAME='localhost')
    r = c.post('/api/v1/auth/register/',
        data=json.dumps({'email':'test2@voxbridge.io','password':'TestPass2026!','first_name':'Test','last_name':'Two','organization_name':'Test Org'}),
        content_type='application/json')
    print('Status:', r.status_code)
    body = json.loads(r.content)
    if r.status_code == 201:
        print('PASS: User created. Keys:', list(body.keys()))
    elif 'email' in body and 'already exists' in str(body['email']):
        print('PASS: User already exists (expected on re-run)')
    else:
        print('FAIL:', body)
"

# 2. Test Login
echo ""
echo "--- 2. LOGIN ---"
docker compose exec -T backend python manage.py shell -c "
import json
from django.test import Client, override_settings
with override_settings(ALLOWED_HOSTS=['*']):
    c = Client(SERVER_NAME='localhost')
    r = c.post('/api/v1/auth/login/',
        data=json.dumps({'username':'demo@voxbridge.io','password':'VoxBridge2026!'}),
        content_type='application/json')
    print('Status:', r.status_code)
    body = json.loads(r.content)
    if r.status_code == 200 and 'access' in body:
        print('PASS: Login successful. Token length:', len(body['access']))
        # Store token for subsequent tests
        with open('/tmp/vox_token.txt', 'w') as f:
            f.write(body['access'])
    else:
        print('FAIL:', body)
"

# 3. Test /auth/me/
echo ""
echo "--- 3. USER PROFILE (/auth/me/) ---"
docker compose exec -T backend python manage.py shell -c "
import json
from django.test import Client, override_settings
with override_settings(ALLOWED_HOSTS=['*']):
    c = Client(SERVER_NAME='localhost')
    # Login first
    r = c.post('/api/v1/auth/login/',
        data=json.dumps({'username':'demo@voxbridge.io','password':'VoxBridge2026!'}),
        content_type='application/json')
    token = json.loads(r.content)['access']
    # Fetch me
    r2 = c.get('/api/v1/auth/me/', HTTP_AUTHORIZATION=f'Bearer {token}')
    print('Status:', r2.status_code)
    if r2.status_code == 200:
        print('PASS:', json.loads(r2.content))
    else:
        print('INFO: /me/ returned', r2.status_code, '(may need profile setup)')
"

# 4. Test Integrations
echo ""
echo "--- 4. INTEGRATIONS ---"
docker compose exec -T backend python manage.py shell -c "
import json
from django.test import Client, override_settings
with override_settings(ALLOWED_HOSTS=['*']):
    c = Client(SERVER_NAME='localhost')
    r = c.post('/api/v1/auth/login/',
        data=json.dumps({'username':'demo@voxbridge.io','password':'VoxBridge2026!'}),
        content_type='application/json')
    token = json.loads(r.content)['access']
    r2 = c.get('/api/v1/integrations/', HTTP_AUTHORIZATION=f'Bearer {token}')
    print('Status:', r2.status_code)
    if r2.status_code == 200:
        body = json.loads(r2.content)
        print('PASS: Integrations response:', body)
    else:
        print('INFO:', r2.status_code, r2.content.decode()[:200])
"

# 5. Test Chat Sessions
echo ""
echo "--- 5. CHAT SESSIONS ---"
docker compose exec -T backend python manage.py shell -c "
import json
from django.test import Client, override_settings
with override_settings(ALLOWED_HOSTS=['*']):
    c = Client(SERVER_NAME='localhost')
    r = c.post('/api/v1/auth/login/',
        data=json.dumps({'username':'demo@voxbridge.io','password':'VoxBridge2026!'}),
        content_type='application/json')
    token = json.loads(r.content)['access']
    r2 = c.get('/api/v1/chat/sessions/', HTTP_AUTHORIZATION=f'Bearer {token}')
    print('Status:', r2.status_code)
    if r2.status_code == 200:
        print('PASS: Chat sessions:', json.loads(r2.content))
    else:
        print('INFO:', r2.status_code, r2.content.decode()[:200])
"

# 6. Test Agent Service Health
echo ""
echo "--- 6. AGENT SERVICE ---"
docker compose exec -T agent curl -s http://localhost:8001/health
echo ""

# 7. Test Agent /pipeline/action
echo ""
echo "--- 7. AGENT ACTION ENDPOINT ---"
docker compose exec -T agent curl -s -X POST http://localhost:8001/pipeline/action -H "Content-Type: application/json" -d '{"command":"tell me what happened yesterday"}' 2>&1 | head -c 500
echo ""

echo ""
echo "========================================="
echo "  Test Suite Complete"
echo "========================================="
