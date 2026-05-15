# Backend (Django) — Customer Balance Proxy + Debt-Limit Gate (implementation prompt)

> Bu hujjatni butunligicha **yangi backend sessiyaga** task brief sifatida nusxalang.
> Self-contained — oldindan kontekst kerak emas.
> **Avval [customer-balance-passport.md](./customer-balance-passport.md) v2'ni o'qing** — bu yagona shartnoma manbai. Hujjat va prompt orasida ziddiyat bo'lsa — passport ustun.
> Mobile tomondagi ish allaqachon bajarilgan (P0 + P1 + P2 fazalari, M12 dan tashqari M2 deferred). Mobile bu yerda yozilgan endpoint'lar deploy bo'lganligini taxmin qiladi.

## Maqsad

1C buxgalteriya SOAP serveriga to'g'ridan-to'g'ri ulanishni mobile'dan **butunlay backendga ko'chirish**. Backend mobile'dan REST so'rovi qabul qiladi, 1C SOAP'ga forward qiladi, response'ni Passport §2.1 shape'ga normalize qiladi, cache'ga yozadi va `(debt_limit != null) AND (balance > debt_limit)` formulasiga binoan `blocked` qarorini qaytaradi.

Qo'shimcha: per-project debt limits endpoint'i va mobile-side analytics event collector.

## Repository

- **Backend repo'si:** `<TODO: backend repo path — masalan, /Users/.../gloria-backend/>`
- **Stack:** Django + DRF (Django REST Framework). PostgreSQL. Celery (kelajakda balance pre-fetch uchun).
- **Mavjud apps:** `apps/tenants/` (Organization), `apps/projects/` (Project), `apps/customers/` (Customer), `apps/sync/` (IntegrationLog), `apps/users/` (User).
- **Test framework:** pytest + pytest-django + factory_boy.
- **Mobile codebase reference:** `/Users/kamoliddin/Documents/GitHub/clone-gg-app/` — to'liq mobile implementation (faqat o'qish uchun, integration test uchun).

## Mavjud kontekst (taxmin qilinadi)

- `apps.tenants.Organization` modelida `customer_scope` (`"organization" | "project"`), `external_balance_url` (1C SOAP), `external_balance_username`/`password`, `external_balance_is_enabled` mavjud.
- `apps.projects.Project` modelida `code`, `id_1c`, `external_balance_project_name`, `debt_limit` (nullable Decimal), `debt_limit_currency` (string, default `"UZS"`).
- `apps.customers.Customer` modelida `code` (`C-XXXXXXXX`), `code_1c` (1C ref), `inn`, `project` (FK).
- V2 mobile auth — Bearer JWT (`apps.auth_v2.middleware`).
- `customers.view_customer` codename allaqachon mavjud va frontend'ga `gates`'da yetkazib berilgan.
- `apps.sync.IntegrationLog` model log uchun.
- **`X-Project-Id` header** allaqachon `customer_read_repository`, `customer_write_repository`, `customer_photo_repository` endpoint'larida o'qilishi kerak — patternni kuzating.

Agar yuqoridagilardan biri yo'q bo'lsa — backend repo'ni grep qilib aniqlang va ushbu prompt'ga moslashtirib **xabar bering** (Passport §1 ma'lumotlar egaligi diagrammasi yangilanishi kerak bo'lishi mumkin).

## Asosiy bosqichlar

### B1 — `Project.debt_limit` + `debt_limit_currency` schema migration

File: `apps/projects/models.py`

Mavjud `Project` modeliga 2 ta yangi field:

```python
debt_limit = models.DecimalField(
    max_digits=20, decimal_places=2, null=True, blank=True,
    help_text='Project debt limit. NULL means no limit (Passport §3).',
)
debt_limit_currency = models.CharField(
    max_length=8, default='UZS',
    help_text='ISO 4217 currency code. Default UZS.',
)
```

Migration: `python manage.py makemigrations projects`. Eski qatorlar default qiymat oladi.

Admin'ga (`apps/projects/admin.py`) ikkala field'ni qo'shing — admin orqali sozlash imkoniyati.

### B2 — `CustomerBalanceCache` model (yangi)

File: `apps/customers/models.py` yoki `apps/customers/balance/models.py`.

```python
class CustomerBalanceCache(models.Model):
    """
    Per-(customer, project) cached balance from 1C SOAP.
    See Passport §1, §4.
    """
    customer = models.ForeignKey('customers.Customer', on_delete=models.CASCADE)
    project = models.ForeignKey('projects.Project', on_delete=models.CASCADE)

    # Top-level fields (Passport §2.1)
    balance = models.DecimalField(max_digits=20, decimal_places=2, default=0)
    currency = models.CharField(max_length=8, default='UZS')
    server_data_updated_at = models.DateTimeField(null=True, blank=True)
    fetched_at = models.DateTimeField(auto_now=True)
    last_error = models.TextField(null=True, blank=True)

    # Snapshot of contract + order arrays (denormalized JSONB).
    # Each item shape per Passport §2.3 / §2.4.
    contract_balances = models.JSONField(default=list)
    order_balances = models.JSONField(default=list)

    class Meta:
        unique_together = [('customer', 'project')]
        indexes = [
            models.Index(fields=['customer', 'project']),
            models.Index(fields=['fetched_at']),
        ]

    def is_fresh(self, ttl_seconds=60):
        """Passport §4: 60s TTL."""
        from django.utils import timezone
        return (timezone.now() - self.fetched_at).total_seconds() < ttl_seconds
```

Migration.

### B3 — `BalanceGateEvent` model (analytics, Passport §3.5)

File: `apps/analytics/models.py` (yangi app yoki mavjud `apps/sync/`'ga qo'shish — codebase pattern'iga qarab).

```python
class BalanceGateEvent(models.Model):
    organization = models.ForeignKey('tenants.Organization', on_delete=models.CASCADE)
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    project = models.ForeignKey('projects.Project', on_delete=models.SET_NULL, null=True)
    customer_code_1c = models.CharField(max_length=64)
    event_name = models.CharField(max_length=64)  # "customer.balance.blocked"
    balance = models.DecimalField(max_digits=20, decimal_places=2)
    debt_limit = models.DecimalField(max_digits=20, decimal_places=2, null=True)
    currency = models.CharField(max_length=8, default='UZS')
    source = models.CharField(max_length=16)
    reason = models.CharField(max_length=64, null=True)
    is_offline = models.BooleanField(default=False)
    is_stale = models.BooleanField(default=False)
    trigger = models.CharField(max_length=32, default='unknown')
    client_timestamp = models.DateTimeField()
    server_timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['organization', 'project', 'server_timestamp']),
            models.Index(fields=['customer_code_1c', 'server_timestamp']),
        ]
```

Migration.

### B4 — Reusable: `X-Project-Id` resolver (DRF mixin)

File: `apps/customers/mixins.py` (yangi) yoki mavjud joyga moslashtiring.

Pattern: hozirgi `customers/`, `customers/{id}/coordinates/`, `customers/{id}/photos/` endpoint'lari `X-Project-Id` o'qiydi (mobile [`customer_read_repository.dart:109-140`](../lib/src/features/agent/data/repositories/customer_read_repository.dart#L109-L140) yuboradi). Shu o'qish mantig'ini reusable mixin/dependency yarating:

```python
class ProjectScopedViewMixin:
    """Resolves X-Project-Id header per Passport §1.5."""

    def get_active_project(self, request):
        org = request.user.organization
        if org.customer_scope != 'project':
            return None  # Org-scope: header ignored.

        header_value = request.headers.get('X-Project-Id')
        if not header_value:
            from rest_framework.exceptions import ValidationError
            raise ValidationError(
                {'error': {
                    'code': 'customer_project_required',
                    'message': 'Active project is not selected.',
                }},
                code='customer_project_required',
            )

        # Try UUID → 1C ref → SOAP code (priority order).
        from apps.projects.models import Project
        try:
            return Project.objects.get(id=header_value, organization=org)
        except (Project.DoesNotExist, ValueError):
            pass
        try:
            return Project.objects.get(id_1c=header_value, organization=org)
        except Project.DoesNotExist:
            pass
        try:
            return Project.objects.get(code=header_value, organization=org)
        except Project.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound({'error': {'code': 'not_found', 'what': 'project'}})
```

### B5 — `POST /api/mobile/v2/customers/balance/` view (Passport §2)

File: `apps/customers/balance/views.py` (yangi).

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.db import transaction
from .serializers import BalanceRequestSerializer, BalanceResponseSerializer
from .services import fetch_balance_via_soap
from .mixins import ProjectScopedViewMixin

class CustomerBalanceView(ProjectScopedViewMixin, APIView):
    permission_classes = [IsAuthenticated]
    required_codename = 'customers.view_customer'

    def post(self, request):
        # 1. Validate body.
        serializer = BalanceRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code_1c = serializer.validated_data['code_1c']
        project_code = serializer.validated_data['project_code']
        force_refresh = serializer.validated_data.get('force_refresh', False)

        # 2. Resolve project via X-Project-Id (project-scope) OR by project_code (org-scope).
        active_project = self.get_active_project(request)
        if active_project:
            # Project-scope: header is the source of truth; project_code is a sanity check.
            if active_project.code != project_code:
                return Response(
                    {'error': {'code': 'validation', 'detail': 'project_code mismatch with X-Project-Id'}},
                    status=400,
                )
            project = active_project
        else:
            # Org-scope: resolve by project_code.
            try:
                project = Project.objects.get(code=project_code, organization=request.user.organization)
            except Project.DoesNotExist:
                return Response({'error': {'code': 'not_found', 'what': 'project'}}, status=404)

        # 3. Resolve customer.
        try:
            customer = Customer.objects.get(
                code_1c=code_1c,
                project=project,  # cross-project leak prevention (Passport §1.5)
            )
        except Customer.DoesNotExist:
            return Response({'error': {'code': 'not_found', 'what': 'customer'}}, status=404)

        # 4. Check organization config.
        org = request.user.organization
        if not org.external_balance_is_enabled or not org.external_balance_url:
            return Response({'error': {'code': 'not_configured'}}, status=503)

        # 5. Cache lookup (TTL 60s, force_refresh skips).
        cache = CustomerBalanceCache.objects.filter(customer=customer, project=project).first()
        if cache and not force_refresh and cache.is_fresh():
            return Response(_serialize_balance(cache, project, source='cache'))

        # 6. Call SOAP.
        try:
            soap_data = fetch_balance_via_soap(
                organization=org,
                project=project,
                customer=customer,
            )
        except Exception as e:
            # Stale fallback if cache exists.
            if cache:
                cache.last_error = str(e)[:500]
                cache.save(update_fields=['last_error'])
                return Response(_serialize_balance(cache, project, source='stale'))
            return Response(
                {'error': {'code': 'upstream_unavailable', 'detail': str(e)[:200]}},
                status=502,
            )

        # 7. Persist cache.
        with transaction.atomic():
            cache, _ = CustomerBalanceCache.objects.update_or_create(
                customer=customer,
                project=project,
                defaults={
                    'balance': soap_data['balance'],
                    'currency': 'UZS',  # backend can keep this fixed for now
                    'server_data_updated_at': soap_data.get('server_data_updated_at'),
                    'last_error': None,
                    'contract_balances': soap_data['contract_balances'],
                    'order_balances': soap_data['order_balances'],
                },
            )

        # 8. Compute blocked decision (Passport §5) + log if blocked.
        response_payload = _serialize_balance(cache, project, source='fresh')
        if response_payload['blocked']:
            IntegrationLog.objects.create(
                endpoint='customers/balance/blocked',
                project=project,
                organization=org,
                # customer FK if your IntegrationLog supports it
                request_payload={
                    'code_1c': code_1c,
                    'project_code': project_code,
                    'balance': str(cache.balance),
                    'debt_limit': str(project.debt_limit),
                },
                response_payload={'reason': 'debt_limit_exceeded'},
                status='OK',
            )

        return Response(response_payload)


def _serialize_balance(cache, project, *, source):
    """Build Passport §2.1 response shape."""
    blocked = (
        project.debt_limit is not None
        and cache.balance > project.debt_limit
    )
    return {
        'inn': cache.customer.inn,
        'client_code': cache.customer.code,
        'project_name': project.external_balance_project_name or project.code,
        'balance': str(cache.balance),                            # Decimal as string (§2.2)
        'currency': cache.currency,
        'debt_limit': str(project.debt_limit) if project.debt_limit is not None else None,
        'debt_limit_currency': project.debt_limit_currency,
        'server_data_updated_at': cache.server_data_updated_at.isoformat() if cache.server_data_updated_at else None,
        'last_updated': cache.fetched_at.isoformat(),
        'blocked': blocked,
        'block_reason': 'debt_limit_exceeded' if blocked else None,
        'source': source,
        'last_error': cache.last_error,
        'contract_balances': cache.contract_balances,
        'order_balances': cache.order_balances,
    }
```

URL: `urls.py` da `path('api/mobile/v2/customers/balance/', CustomerBalanceView.as_view())`.

### B6 — SOAP service layer (`fetch_balance_via_soap`)

File: `apps/customers/balance/services/soap_client.py`.

Mavjud mobile [`client_balance_service.dart`](../lib/src/core/services/client_balance_service.dart) M1'gacha versiyasidagi SOAP envelope va parsing logikasini Python'da takrorlang. Real fixture `docs/customer-balance-passport.md` §9'da.

```python
import requests
from defusedxml import ElementTree as ET
from apps.sync.models import IntegrationLog
import time

def fetch_balance_via_soap(*, organization, project, customer):
    envelope = _build_soap_envelope(
        inn=customer.inn,
        project_external_name=project.external_balance_project_name or project.code,
    )
    headers = {
        'Content-Type': 'application/soap+xml; charset=utf-8',
        'SOAPAction': '',
    }
    auth = (organization.external_balance_username, organization.external_balance_password)

    started = time.monotonic()
    log_status = 'OK'
    response_text = None
    try:
        response = requests.post(
            organization.external_balance_url,
            data=envelope,
            headers=headers,
            auth=auth,
            timeout=15,
        )
        response_text = response.text
        response.raise_for_status()
        return _parse_soap_response(response_text)
    except requests.Timeout:
        log_status = 'TIMEOUT'
        raise
    except requests.HTTPError as e:
        log_status = 'HTTP_ERROR'
        raise
    except requests.RequestException as e:
        log_status = 'TRANSPORT_ERROR'
        raise
    finally:
        IntegrationLog.objects.create(
            endpoint=organization.external_balance_url,
            project=project,
            organization=organization,
            request_payload=envelope[:5000],
            response_payload=(response_text or '')[:5000],
            status=log_status,
            duration_ms=int((time.monotonic() - started) * 1000),
        )


def _build_soap_envelope(*, inn, project_external_name):
    return f'''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GeClientBalance>
         <sam:INN>{inn}</sam:INN>
         <sam:Project>{project_external_name}</sam:Project>
      </sam:GeClientBalance>
   </soap:Body>
</soap:Envelope>'''


def _parse_soap_response(xml_string):
    """
    Per Passport §6 edge cases:
    - Negative balance ('-2250')
    - status='Переплата' (Cyrillic, verbatim)
    - xsi:nil="true" → None
    - empty <m:orderNumber/> → ''
    - timezone-naive <m:updatedDateTime>
    - Cyrillic + double whitespace preserved
    - Integer-like decimals as strings ('5356620')
    """
    # Use defusedxml for security.
    ns = {
        'soap': 'http://www.w3.org/2003/05/soap-envelope',
        'm': 'http://www.sample-package.org',
        'xsi': 'http://www.w3.org/2001/XMLSchema-instance',
    }
    root = ET.fromstring(xml_string)
    return_el = root.find('.//m:return', ns)
    if return_el is None:
        raise ValueError('No <m:return> in SOAP response')

    balance = (return_el.findtext('m:balance', default='0', namespaces=ns) or '0').strip()
    updated_dt = return_el.findtext('m:updatedDateTime', default=None, namespaces=ns)

    contracts = [_parse_contract(el, ns) for el in return_el.findall('m:ClientBalanceByContract', ns)]
    orders = [_parse_order(el, ns) for el in return_el.findall('m:ClientBalanceByOrder', ns)]

    return {
        'balance': balance,
        'server_data_updated_at': _parse_naive_dt(updated_dt),
        'contract_balances': contracts,
        'order_balances': orders,
    }


# Helper details: _parse_contract, _parse_order, _parse_naive_dt, _is_xsi_nil
# — implementatsiyani Passport §6 va §9'dagi real fixture bo'yicha amalga oshiring va
#   testlar bilan tasdiqlang (B11).
```

**Critical edge case'lar (B11 testlarida):**
- `balance="-2250"` (manfiy, oldindan to'lov)
- `<m:orderDate xsi:nil="true"/>` → JSON `null`
- `<m:orderNumber/>` (bo'sh) → JSON `""`
- `status="Переплата"` (Cyrillic verbatim)
- `<m:updatedDateTime>2026-05-14T00:00:00</m:updatedDateTime>` (TZ-naive — verbatim string sifatida saqlash, parsing qilmaslik)
- `<m:projectName>Проект  ТМ "AVON"</m:projectName>` (qo'sh probel + Cyrillic + qo'shtirnoq)

### B7 — `GET /api/mobile/v2/projects/config/` view (Passport §3)

File: `apps/projects/views.py` (yangi yoki mavjud `ProjectViewSet`'ga `@action` qo'shish).

```python
class ProjectsConfigView(ProjectScopedViewMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # X-Project-Id qabul qilinadi lekin filter sifatida ishlatilmaydi
        # (har bir foydalanuvchining BARCHA loyihalari qaytariladi).
        # Project-scope tenant'larda ham faqat header validation maqsadida
        # mixin chaqiriladi.
        self.get_active_project(request)  # raises if missing in project-scope

        projects = Project.objects.filter(
            organization=request.user.organization,
            users=request.user,  # foydalanuvchiga ko'rinadigan
        )

        return Response([
            {
                'code': p.code,
                'debt_limit': str(p.debt_limit) if p.debt_limit is not None else None,
                'debt_limit_currency': p.debt_limit_currency,
            }
            for p in projects
        ])
```

URL: `path('api/mobile/v2/projects/config/', ProjectsConfigView.as_view())`.

### B8 — `POST /api/mobile/v2/analytics/balance-gate/` view (Passport §3.5)

File: `apps/analytics/views.py` (yangi yoki sin `apps/sync/`'ga).

```python
class BalanceGateAnalyticsView(ProjectScopedViewMixin, APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # X-Project-Id ham qabul qilinadi (lekin majburiy emas — mobile
        # uni "best-effort" rejimida yuboradi). Project-scope tenant'larda
        # mixin "customer_project_required" qaytarsa OK — mobile event'ni
        # silently swallow qiladi.
        try:
            project = self.get_active_project(request)
        except ValidationError:
            return Response(status=204)  # silently accept

        serializer = BalanceGateEventSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        BalanceGateEvent.objects.create(
            organization=request.user.organization,
            user=request.user,
            project=project,  # may be None for org-scope
            customer_code_1c=data['code_1c'],
            event_name=data['event'],
            balance=Decimal(str(data['balance'])),
            debt_limit=Decimal(str(data['limit'])) if data.get('limit') is not None else None,
            currency=data['currency'],
            source=data['source'],
            reason=data.get('reason'),
            is_offline=data['is_offline'],
            is_stale=data['is_stale'],
            trigger=data['trigger'],
            client_timestamp=data['timestamp'],
        )

        return Response(status=204)
```

Serializer validation qoidalari Passport §3.5'dagi shape jadvaliga binoan.

URL: `path('api/mobile/v2/analytics/balance-gate/', BalanceGateAnalyticsView.as_view())`.

### B9 — Error envelope standartlash

Hozir DRF'ning default error envelope'i Passport §2.5 shape'ga mos kelmasligi mumkin. Custom exception handler:

File: `apps/api/exception_handler.py` (yangi yoki mavjud).

```python
def custom_exception_handler(exc, context):
    from rest_framework.views import exception_handler
    response = exception_handler(exc, context)
    if response is None:
        return None

    # Wrap into Passport §2.5 shape if not already wrapped.
    data = response.data
    if isinstance(data, dict) and 'error' not in data:
        # Try to detect existing envelope shape.
        if 'detail' in data:
            response.data = {
                'error': {
                    'code': _classify_status_to_code(response.status_code),
                    'message': str(data['detail']),
                }
            }
    return response


def _classify_status_to_code(status_code):
    return {
        400: 'validation',
        403: 'forbidden',
        404: 'not_found',
        502: 'upstream_unavailable',
        503: 'not_configured',
    }.get(status_code, 'unknown')
```

`settings.py`'ga: `REST_FRAMEWORK = {'EXCEPTION_HANDLER': 'apps.api.exception_handler.custom_exception_handler'}`.

### B10 — Admin'ga ko'rinish

File: `apps/customers/admin.py` (CustomerBalanceCache uchun), `apps/analytics/admin.py` (BalanceGateEvent uchun).

`CustomerBalanceCache` admin: `customer`, `project`, `balance`, `fetched_at`, `last_error` columns. Search by `customer__inn`, `customer__code_1c`. Read-only — admin qo'lda o'zgartirmasligi kerak.

`BalanceGateEvent` admin: `organization`, `user`, `customer_code_1c`, `event_name`, `balance`, `debt_limit`, `reason`, `server_timestamp`. Filter by `event_name`, `reason`, `trigger`. Read-only.

### B11 — Tests

File: `apps/customers/balance/tests/`.

Pattern: `pytest_django.fixtures` + `factory_boy` factories.

#### `test_soap_parsing.py` — Passport §6 edge case'lar (kritik)

```python
@pytest.mark.parametrize('xml_path,expected', [
    ('fixtures/balance_negative.xml', {'balance': '-2250', 'orders[0].status': 'Переплата'}),
    ('fixtures/balance_xsi_nil.xml', {'orders[0].order_date': None}),
    ('fixtures/balance_cyrillic.xml', {'contracts[0].project_name': 'Проект  ТМ "AVON"'}),
    ('fixtures/balance_empty_elements.xml', {'orders[0].order_number': ''}),
    ('fixtures/balance_tz_naive.xml', {'server_data_updated_at': '2026-05-14T00:00:00'}),
])
def test_soap_parsing_passport_edge_cases(xml_path, expected):
    xml = (FIXTURES_DIR / xml_path).read_text()
    parsed = _parse_soap_response(xml)
    for path, value in expected.items():
        assert _resolve_path(parsed, path) == value
```

Real fixture'lar: Passport §9'dagi sample'ni boshlang'ich nuqta sifatida ishlating.

#### `test_balance_endpoint.py` — `POST /customers/balance/` end-to-end

Mock SOAP layer, real DB:

```python
def test_balance_returns_passport_2_1_shape(api_client, project, customer, mock_soap):
    mock_soap.return_value = {...}  # fake SOAP response
    response = api_client.post(
        '/api/mobile/v2/customers/balance/',
        data={'code_1c': customer.code_1c, 'project_code': project.code, 'force_refresh': False},
        headers={'X-Project-Id': str(project.id)},
    )
    assert response.status_code == 200
    body = response.json()
    # Passport §2.1 shape.
    assert set(body.keys()) >= {
        'inn', 'client_code', 'project_name', 'balance', 'currency',
        'debt_limit', 'debt_limit_currency', 'server_data_updated_at',
        'last_updated', 'blocked', 'block_reason', 'source', 'last_error',
        'contract_balances', 'order_balances',
    }
    assert body['source'] == 'fresh'
    assert isinstance(body['balance'], str)  # Passport §2.2 — string Decimal


def test_balance_blocked_when_over_limit(api_client, project_with_limit, customer, mock_soap):
    mock_soap.return_value = {'balance': '6000000', ...}  # over 5M limit
    response = api_client.post(...)
    assert response.json()['blocked'] is True
    assert response.json()['block_reason'] == 'debt_limit_exceeded'
    # IntegrationLog should have a 'customers/balance/blocked' row.
    assert IntegrationLog.objects.filter(endpoint='customers/balance/blocked').count() == 1


def test_balance_returns_503_when_not_configured(api_client, customer, project):
    customer.organization.external_balance_is_enabled = False
    customer.organization.save()
    response = api_client.post(...)
    assert response.status_code == 503
    assert response.json() == {'error': {'code': 'not_configured'}}


def test_balance_returns_502_when_upstream_down_and_no_cache(api_client, project, customer, mock_soap):
    mock_soap.side_effect = requests.Timeout()
    response = api_client.post(...)
    assert response.status_code == 502
    assert response.json()['error']['code'] == 'upstream_unavailable'


def test_balance_returns_stale_when_upstream_down_with_cache(api_client, project, customer, mock_soap):
    CustomerBalanceCacheFactory(customer=customer, project=project, balance='1000')
    mock_soap.side_effect = requests.Timeout()
    response = api_client.post(...)
    assert response.status_code == 200
    assert response.json()['source'] == 'stale'


def test_balance_x_project_id_required_for_project_scope(api_client_project_scope, customer, project):
    response = api_client_project_scope.post(
        '/api/mobile/v2/customers/balance/',
        data={'code_1c': customer.code_1c, 'project_code': project.code},
        # NO X-Project-Id header
    )
    assert response.status_code == 400
    assert response.json()['error']['code'] == 'customer_project_required'


def test_balance_cross_project_leak_prevention(api_client, project_a, project_b, customer_in_a):
    """Customer is in project A, request comes for project B — must 404."""
    response = api_client.post(
        '/api/mobile/v2/customers/balance/',
        data={'code_1c': customer_in_a.code_1c, 'project_code': project_b.code},
        headers={'X-Project-Id': str(project_b.id)},
    )
    assert response.status_code == 404


def test_balance_cache_ttl_60s(api_client, project, customer, mock_soap, freezer):
    # First call → SOAP hit + cache write.
    response1 = api_client.post(...)
    assert response1.json()['source'] == 'fresh'
    assert mock_soap.call_count == 1

    # Within 60s → cache hit.
    freezer.tick(50)
    response2 = api_client.post(...)
    assert response2.json()['source'] == 'cache'
    assert mock_soap.call_count == 1  # no extra SOAP call

    # Past 60s → SOAP hit again.
    freezer.tick(20)
    response3 = api_client.post(...)
    assert response3.json()['source'] == 'fresh'
    assert mock_soap.call_count == 2


def test_balance_force_refresh_skips_cache(api_client, project, customer, mock_soap):
    response1 = api_client.post(..., data={'force_refresh': False})
    response2 = api_client.post(..., data={'force_refresh': True})
    assert mock_soap.call_count == 2
```

#### `test_projects_config.py`

```python
def test_projects_config_returns_array(api_client, user, projects):
    response = api_client.get('/api/mobile/v2/projects/config/')
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    for entry in response.json():
        assert set(entry.keys()) == {'code', 'debt_limit', 'debt_limit_currency'}


def test_projects_config_only_user_visible_projects(api_client, user, project_a, project_b_other_user):
    response = api_client.get('/api/mobile/v2/projects/config/')
    codes = {e['code'] for e in response.json()}
    assert project_a.code in codes
    assert project_b_other_user.code not in codes


def test_projects_config_null_debt_limit(api_client, user, project_no_limit):
    response = api_client.get('/api/mobile/v2/projects/config/')
    entry = next(e for e in response.json() if e['code'] == project_no_limit.code)
    assert entry['debt_limit'] is None
```

#### `test_analytics_balance_gate.py`

```python
def test_analytics_event_persisted(api_client, user, project):
    payload = {
        'event': 'customer.balance.blocked',
        'code_1c': '00-00053242',
        'project_code': project.code,
        'balance': -2250.0,
        'limit': 5000000.0,
        'currency': 'UZS',
        'source': 'fresh',
        'reason': 'debt_limit_exceeded',
        'is_offline': False,
        'is_stale': False,
        'trigger': 'visit_step_entry',
        'timestamp': '2026-05-14T12:00:00Z',
    }
    response = api_client.post('/api/mobile/v2/analytics/balance-gate/', data=payload)
    assert response.status_code == 204
    assert BalanceGateEvent.objects.count() == 1
    event = BalanceGateEvent.objects.first()
    assert event.customer_code_1c == '00-00053242'
    assert event.reason == 'debt_limit_exceeded'
    assert event.trigger == 'visit_step_entry'


def test_analytics_silently_accepts_missing_x_project_id(api_client_project_scope_no_active):
    """Mobile silently swallows; backend should return 204 even if scope mismatches."""
    response = api_client_project_scope_no_active.post(
        '/api/mobile/v2/analytics/balance-gate/',
        data={'event': 'customer.balance.blocked', ...},
    )
    assert response.status_code == 204
```

### B12 — Pre-deploy regression

Ishlab chiqishdan oldin manual smoke test:

1. `python manage.py runserver 0.0.0.0:8080`.
2. Mobile device'ni `http://192.168.0.X:8080`'ga ulang.
3. [Mobile backend audit doc](customer-balance-backend-requirements.md) §2.3 va §2.4'dagi 7 ta scenario'ni o'tkazing.
4. Charles Proxy bilan kuzating: `kit.gloriya.uz`, `178.218.200.120`, `109.94.175.104` host'lariga **mobile'dan hech qanday so'rov ketmasligi** (faqat backend SOAP qiladi).

### B13 — Celery balance pre-fetch (optional, Phase 2)

Mobile bootstrap vaqtida (post-login) `CustomerBalanceStatusCache.bootstrap()` chaqiradi. Bu DB'dagi mavjud `client_balances`'ni o'qiydi. Backend tomonida:

- Celery task: har bir `(active customer × user's project)` uchun balansni fonda fetch qilish (har 60 daqiqada).
- Mobile bootstrap'i shundan so'ng "warm cache" oladi.

Hozircha **out of scope**, lekin model va endpoint'lar ushbu kelajakdagi optimization'ni qo'llab-quvvatlaydi.

## Done definition

- [ ] `pytest apps/customers/balance/` yashil — barcha §6 edge case'lar.
- [ ] `pytest apps/projects/test_config_endpoint.py` yashil.
- [ ] `pytest apps/analytics/test_balance_gate.py` yashil.
- [ ] Mobile real device'dan `POST /customers/balance/` chaqirig'i 200 + Passport §2.1 shape qaytaradi.
- [ ] Mobile real device'dan `GET /projects/config/` chaqirig'i 200 + array qaytaradi.
- [ ] `X-Project-Id` etishmasa project-scope tenant'da 400 + `customer_project_required`.
- [ ] Cross-project leak preventatsiya test: customer A'da, request B'ga → 404.
- [ ] `IntegrationLog` har SOAP chaqiruv uchun yoziladi.
- [ ] `BalanceGateEvent` analytics POST'lar uchun yoziladi.
- [ ] `not_configured`, `upstream_unavailable`, `not_found`, `forbidden` error envelope'lar Passport §2.5 shape'da.
- [ ] Mobile [`docs/customer-balance-backend-requirements.md`](customer-balance-backend-requirements.md) §1.1–§1.7 chek-listi to'liq.

## Rollout order

1. **B1 + B2 + B3** — schema migration'lar (yangi field/model'lar mavjud bo'lishini ta'minlash).
2. **B4** — reusable `X-Project-Id` mixin (boshqa endpoint'lar ham foydalanadi).
3. **B6 + B5** — SOAP service + `customers/balance/` view.
4. **B7** — `projects/config/` view.
5. **B8** — `analytics/balance-gate/` view.
6. **B9** — error envelope unifier.
7. **B10** — admin.
8. **B11** — testlar (fixtures'ga `apps/customers/balance/tests/fixtures/`'da Passport §9 sample'ni qo'ying).
9. **B12** — manual smoke + Charles Proxy audit.

## Mobile bog'liqligi

Mobile P0/P1 ishlari allaqachon bajarilgan ([customer-balance-mobile.md](customer-balance-mobile.md) M1–M14 + texnik kamchilik plan P0–P2):

- [`ClientBalanceService.fetchClientBalance`](../lib/src/core/services/client_balance_service.dart#L114-L176) — `POST /customers/balance/` chaqiradi + `X-Project-Id` header.
- [`DataSyncService._syncProjectsConfig`](../lib/src/core/services/data_sync_service.dart#L2382-L2418) — `GET /projects/config/` chaqiradi + `X-Project-Id` header.
- [`BalanceGateEventLogger.logBlocked`](../lib/src/features/agent/services/balance_gate_event_logger.dart) — `POST /analytics/balance-gate/` chaqiradi (best-effort, failure swallowed).
- [`CustomerEndpointHeaders`](../lib/src/core/network/customer_endpoint_headers.dart) — `X-Project-Id` injection helper.

Backend B1–B12 deploy bo'lgach mobile yoki **avtomatik ishlaydi** yoki kichik QA scenario'lar bilan tekshiriladi (Done definition'ning 4-/5-bandi).

## Backend tomondan e'tibor talab qiluvchi savollar

1. **`Customer` modelida `inn` va `code_1c` mavjudmi?** Mavjud bo'lmasa migration kerak. Mobile [`TradingPoint.code1c`](../lib/src/features/agent/data/models/trading_point.dart#L47) shu field'ni yuboradi.
2. **`Project.users` M2M mavjudmi?** §B7 query shu munosabatni taxmin qiladi. Aks holda `UserProjectMembership` orqali alternative resolution.
3. **`apps.sync.IntegrationLog` `customer` FK'ni qo'llab-quvvatlaydimi?** §7.2 block decision logging uchun foydali. Aks holda `request_payload` JSON'da `customer_code_1c` saqlash.
4. **Decimal vs string serialization** — DRF default `DecimalField` int yoki string sifatida qaytarishini sozlash kerak (Passport §2.2 string'ni talab qiladi). `coerce_to_string=True` (default) — ehtiyot bo'ling.
5. **Throttling** — `customers/balance/` har bir mijozni ochishda chaqiriladi. Per-user rate limit qo'yish mumkinmi? Backend cache TTL 60s — buni mobile kontekstida ham 10s sifatida saqlash kerakmi (mobile `refreshCooldownSeconds`)?
