#!/bin/bash

# =========================
# 🔧 CONFIG (UPDATE THESE)
# =========================
TENANT_ID="f7de8a06-160f-44b8-9382-8095d1ba8b0d"
CLIENT_ID="30c1f20c-f21d-4c43-ab89-43d8439b94e8"
#  dev
# WORKSPACE_ID="7d828536-a77b-4966-811c-c3b7a0c2770b" 
# finops prod
# WORKSPACE_ID="452befef-c038-4d8d-b244-8d8c87178c92" 
# finops dev
WORKSPACE_ID="30bed2ca-613d-4599-ba23-af433407521c"

echo "========================================"
echo "🔍 STEP 0: Identity Check"
echo "========================================"

az account show --query "{user:user.name, type:user.type, tenantId:tenantId}" -o json

echo "========================================"
echo "🔍 STEP 1: Check Tenant ID"
echo "========================================"
CURRENT_TENANT=$(az account show --query tenantId -o tsv)

echo "Current Tenant: $CURRENT_TENANT"
echo "Expected Tenant: $TENANT_ID"

if [ "$CURRENT_TENANT" != "$TENANT_ID" ]; then
  echo "❌ Tenant mismatch! Run: az login --tenant $TENANT_ID"
  exit 1
else
  echo "✅ Tenant ID is correct"
fi

echo ""
echo "========================================"
echo "🔍 STEP 4: Get Power BI Access Token"
echo "========================================"
TOKEN=$(az account get-access-token \
  --resource https://analysis.windows.net/powerbi/api \
  --query accessToken -o tsv)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
else
  echo "✅ Token acquired"
fi

echo ""
echo "========================================"
echo "🔍 STEP 5: Call Power BI API"
echo "========================================"

HTTP_STATUS=$(curl -s -o response.json -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  https://api.powerbi.com/v1/workspaces/$WORKSPACE_ID)

echo "HTTP Status: $HTTP_STATUS"
echo "Response:"
cat response.json
echo ""

echo ""
echo "========================================"
echo "📊 RESULT"
echo "========================================"

if [ "$HTTP_STATUS" == "200" ]; then
  echo "✅ SUCCESS: You have access to the workspace"
elif [ "$HTTP_STATUS" == "403" ]; then
  echo "❌ ERROR: InsufficientPrivileges"
  echo "👉 FIX: Add Service Principal to workspace as ADMIN"
elif [ "$HTTP_STATUS" == "401" ]; then
  echo "❌ ERROR: Unauthorized"
  echo "👉 FIX: Check Client ID / Tenant ID / login"
else
  echo "⚠️ Unexpected response"
fi