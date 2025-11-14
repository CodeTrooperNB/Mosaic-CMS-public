# Medicus E‑Commerce Hub – Client App Integration Guide

> **Audience:** Technical implementation agents integrating a downstream e-commerce channel with the Medicus GraphQL hub.
>
> **Goal:** Equip you with precise, end-to-end instructions to authenticate, query, mutate, and operate against the `/graphql` endpoint securely and efficiently.

This document complements the GraphQL schema by spelling out control-plane configuration, runtime expectations, security hardening, and canonical request/response flows. Treat it as the source of truth for how client apps must behave in production.

---

## 1. System Overview

### 1.1 Architecture
- **Entry point:** All read/write operations funnel through a single HTTPS endpoint `POST /graphql` hosted by this Rails application.
- **Multi-tenant separation:** Each retail brand is backed by its own database schema. Tenant selection is keyed off the request subdomain (`{brand}.example.com`) and the client-app brand binding.
- **Dual-layer authentication:**
  1. **API credential plane** – identifies the calling integration via `X-Client-Id` + `X-API-Key` headers.
  2. **Customer identity plane** – optional JWT bearer token (`Authorization: Bearer ...`) for logged-in end users.
- **Transport:** Supports single GraphQL operations or batched arrays. Responses always conform to the GraphQL spec (`{ data, errors? }` or an ordered array thereof).
- **Dataloader-enabled resolvers:** Prevent N+1 queries and include pagination helpers, loaders, and targeted scopes.

### 1.2 Critical Components
- `app/controllers/graphql_controller.rb`: request lifecycle orchestration, multiplex support, context injection, error policy.
- `app/services/graphql/authentication.rb`: API key validation, brand connection switching, JWT decoding, correlation ID issuance.
- `app/graphql/**`: schema, types, resolvers, and mutations.
- `app/models/client_app.rb`: client credential lifecycle (issue, rotate, revoke) with bcrypt + SHA256 storage.
- Admin UI (`/admin/client_apps`): human interface for managing client apps.

---

## 2. Provisioning a Client App

Perform these steps from the admin console (`/admin`), using an account with sufficient privileges.

1. **Navigate to Integrations → Client Apps.**
2. **Create a new client app:**
   - Select the brand the integration targets.
   - Provide a human-readable name (e.g., `ShopFront ZA`).
   - Set the *signing secret* (`api_secret`) used for downstream JWT generation.
   - Save. On first save the system auto-generates an API key pair and flashes the plaintext value once.
3. **Capture credentials immediately:**
   - `client_id` – UUID primary key of the record.
   - `api_key` – 240-bit, urlsafe base64 string. **Only shown once**; store securely.
   - `api_secret` – persisted in DB, but treat as sensitive and distribute via secrets management.
4. **Distribute to the integrating agent:** The runtime integration requires these constants:
   - `CLIENT_ID` → `X-Client-Id`
   - `API_KEY` → `X-API-Key`
   - `API_SECRET` → used to sign customer JWTs if generated out-of-band.

### 2.1 Credential Maintenance
- **Rotate key:** From client app show page, click “Rotate API key”. Copy the new plaintext key and update all clients atomically.
- **Revoke key:** “Revoke API key” instantly invalidates header auth until rotated again.
- **Hints & telemetry:** Admin list shows key hint (last 6 chars), creation timestamp, and last-used timestamp to monitor activity.

---

## 3. Runtime Configuration Requirements

| Concern | Setting | Location | Notes |
| --- | --- | --- | --- |
| Allowed origins | `HUB_GRAPHQL_ALLOWED_ORIGINS` | ENV | Comma/space separated list of origin URLs; powers Rack::Cors for `/graphql`. Empty string disables CORS relaxation (default deny).
| Introspection (prod) | `HUB_GRAPHQL_INTROSPECTION` | ENV | `enabled` to permit; otherwise disabled in production via schema hook.
| Devise JWT secret | `Settings.devise_jwt_secret_key` | `config/settings.yml` | Must match any upstream service that issues customer JWTs.
| Host subdomain | Request URL | N/A | Set host to `{brand_subdomain}.your-domain.tld`. Brand must match ClientApp.brand or auth fails.

### 3.1 Headers Required per Request
```
POST https://{brand}.example.com/graphql
Content-Type: application/json
X-Client-Id: <CLIENT_ID>
X-API-Key: <API_KEY>
Authorization: Bearer <CUSTOMER_JWT>    # optional
X-Correlation-ID: <UUID or trace id>    # optional, generated if absent
```

### 3.2 Customer JWT Specification
- Algorithm: `HS256`
- Signing secret: `Settings.devise_jwt_secret_key`
- Subject claim (`sub`): Customer UUID (matches `customers.id`).
- Typical claims: `exp`, `iat`, `jti` (Devise uses JTIMatcher for revocation).
- Invalid or missing JWT yields `UNAUTHENTICATED` GraphQL errors for customer-scoped operations; read-only queries without customer context still execute if API key is valid.

---

## 4. GraphQL Endpoint Behaviour

### 4.1 Request Body Shapes
- **Single operation**
  ```json
  { "query": "query Q { products(offset:0, limit:10) { count items { id styleName } } }" }
  ```
- **Batched**
  ```json
  [
    { "query": "{ products(offset:0, limit:5) { count } }" },
    { "query": "{ me { email } }", "operationName": "CurrentUser" }
  ]
  ```
- Variables accepted as JSON objects or stringified JSON.

### 4.2 Context Values Available to Resolvers
| Key | Description |
| --- | --- |
| `apiKeyValid` | Always `true` when execution begins (auth had passed). |
| `currentCustomer` | `Customer` model instance or `nil`. |
| `current_brand` | Active `Brand` record. |
| `client_app` | `ClientApp` record bound to headers. |
| `correlationId` | Unique ID for tracing/logging. |

### 4.3 Error Model
- Transport-level (non-200) only for malformed requests (invalid JSON, no query, method not allowed) or fatal server errors.
- GraphQL errors follow `{ "errors": [{ "message": ..., "extensions": { "code": <CODE>, "correlationId": <UUID> } }] }`.
- Business rule failures (e.g., invalid coupon) surface via mutation payload fields (`success`, `errors`).

### 4.4 Pagination & Sorting
- Offset/limit pattern with required `offset` & `limit` arguments on list queries.
- Collection types return `{ items: [...], count: Int }` for total counts.
- Sorting uses `ProductSortInput` with `field` (`PRICE`, `CREATED_AT`, `STYLE_NAME`) & `direction` (`ASC`, `DESC`).

### 4.5 Performance Guarantees
- Target P95 latency under 400 ms assuming queries stay within recommended limits (`limit <= 100`).
- Dataloader prevents N+1 for associations (options, stocks, benefits, price, etc.).
- Short-lived caching permissible on client side, not currently built into resolvers.

---

## 5. High-Value Queries & Mutations

Below are canonical operations with expected responses.

### 5.1 Catalogue
- `products(offset:Int!, limit:Int!, q:String, filters:ProductFilterInput, sort:ProductSortInput)` → `ProductCollectionType`
- `product(id:ID, slug:String)`
- `relatedProducts(productId:ID!, offset:Int, limit:Int)`

**Filter input notes:**
- `catalogueEcommId`, `categoryId`, `optionIds`, `colorIds`, `featured`, `isNew`, `priceMin`, `priceMax`.
- Colour filter matches prime or secondary colour IDs.

### 5.2 Customer Context
- `me` – returns `CustomerType` if JWT present.
- `addresses(includeInactive:Boolean)` – requires JWT; returns current or all addresses.
- `orders(offset, limit, status)` – customer’s orders with items, transactions, refunds.
- `refunds(offset, limit)` – refund requests initiated by the customer.

### 5.3 Cart & Checkout
- `cart(id: ID)` – fetch specific cart; without `id` uses the latest cart for current customer.
- `updateCart(input: CartUpdateInput!)` – upserts cart lines, applies coupon.
- `applyCoupon`, `removeCoupon` – manage promotions.
- `checkout(input: CheckoutInput!)` – creates an order, persists delivery address, and clears cart items.
- `requestRefund(input: RefundRequestInput!)` – file refund for order items.

### 5.4 Authentication
- `login(input: LoginInput!)` – returns JWT token and customer attributes.
- `signup(input: SignupInput!)` – creates customer + returns JWT.

### 5.5 Supporting Data
- `paymentMethods` – static list of enabled payment providers, includes installment support flag.
- `shippingOptions(postalCode, zoneId)` – dynamic cost/timeframe based on zone lookup (`Graphql::ShippingOptionResolver`).
- `coupons(autoOnly:Boolean)` – active coupons (possibly filtered to automatic ones).

### 5.6 Example Mutation Flow (Checkout)
```graphql
mutation UpdateCart($cart: CartUpdateInput!) {
  updateCart(input: $cart) {
    success
    errors
    cart { id items { quantity product { id styleName currentPrice } } }
  }
}
```
```json
{
  "cart": {
    "items": [ { "productId": "uuid", "quantity": 2, "sizeId": "uuid" } ],
    "couponCode": "WINTER20"
  }
}
```
Follow with `checkout` mutation specifying payment/shipping identifiers. Validate the response payload (`success`, `errors`, `order`) and capture the resulting `order.id` for future retrieval.

---

## 6. Admin Toolkit Summary

| Action | Location | Notes |
| --- | --- | --- |
| Manage Client Apps | `Admin → Integrations → Client Apps` | List view shows key hints & telemetry. |
| Rotate/Revoke API Key | Client App show page | Rotation flashes new key. Revoke wipes digests. |
| See GraphQL schema JSON | `bin/rails graphql:dump` | Outputs to `schema/schema.json`. Requires bundler setup (see §9). |
| Configure allowed origins | Environment variable | See §3. |

---

## 7. Integration Checklist for Downstream Agent

1. **Obtain credentials** (`client_id`, `api_key`, `api_secret`) from provisioning steps.
2. **Pick target brand**, note subdomain (e.g., `merrell.example.com`). All requests must address that host.
3. **Set environment variables** on your client application:
   ```bash
   MEDICUS_CLIENT_ID=...
   MEDICUS_API_KEY=...
   MEDICUS_BRAND_HOST=merrell.example.com
   MEDICUS_JWT_SECRET=<Settings.devise_jwt_secret_key>
   ```
4. **Build HTTP client with:**
   - `Content-Type: application/json`
   - `X-Client-Id`, `X-API-Key`
   - Optional `Authorization` header when acting on behalf of a customer.
   - Optional `X-Correlation-ID` for trace propagation.
5. **Implement login flow:**
   - Call `login` mutation with user credentials.
   - Store JWT (`token`) client-side (honor `exp`).
6. **Consume catalogue queries** to display storefront data. Observe pagination fields.
7. **Orchestrate cart/checkout** using provided mutations, ensuring you pass the JWT for authenticated operations.
8. **Gracefully handle GraphQL errors:**
   - Inspect `errors[].extensions.code`. For auth errors, refresh credentials or prompt login.
   - For validation issues, surface `errors` array from mutation payload.
9. **Monitor key lifecycle:**
   - Support key rotation: design config reload with minimal downtime.
   - Alert on `UNAUTHENTICATED` errors that persist.
10. **Optional: batch requests** to coalesce dependent operations (the controller supports array payloads).

---

## 8. Security Considerations

- **Never log API keys or bearer tokens.** Mask headers at logging ingress.
- **Refrain from enabling introspection** in production unless necessary for tooling, and disable afterward.
- **CORS restrictions** – ensure your public host is whitelisted via `HUB_GRAPHQL_ALLOWED_ORIGINS` before using browsers.
- **JWT issuance** – aligning with Devise configuration is crucial; mismatched secrets produce `Invalid bearer token` errors.
- **Brand/tenant mismatches** – if `X-Client-Id` brand differs from request subdomain, authentication fails intentionally.
- **Correlation IDs** – propagate across distributed systems for observability; the hub returns the ID per error for debugging.

---

## 9. Local Testing & Tooling

> Bundler 2.6.7 (or compatible 2.6.x) is required to run Rails tasks/tests. Install via `gem install bundler -v 2.6.7` before executing commands.

| Task | Command | Notes |
| --- | --- | --- |
| Run schema dump | `bin/rails graphql:dump` | Requires database connectivity and schema defined. |
| Execute integration test | `bin/rails test test/integration/graphql_hub_test.rb` | Ensures key flows (auth, cart, checkout) pass. Set up bundler first. |
| Launch server | `bin/rails server` | Ensure `config/master.key` present. |
| Seed data | `rails db:seed` | As per README, includes admin login. |

---

## 10. Reference: GraphQL Schema Snapshot

The authoritative schema is produced by `bin/rails graphql:dump` and saved to `schema/schema.json`. For quick orientation, the following SDL excerpt mirrors the current implementation. Keep this section updated when the schema evolves.

```graphql
schema {
  query: Query
  mutation: Mutation
}

type Query {
  node(id: ID!): Node
  nodes(ids: [ID!]!): [Node]

  # Catalogue
  products(offset: Int!, limit: Int!, q: String, filters: ProductFilterInput, sort: ProductSortInput): ProductCollection!
  product(id: ID, slug: String): Product
  relatedProducts(productId: ID!, offset: Int = 0, limit: Int = 8): ProductCollection!

  # Cart & commerce
  cart(id: ID): Cart
  paymentMethods: [PaymentMethod!]!
  shippingOptions(postalCode: String, zoneId: ID): [ShippingOption!]!
  coupons(autoOnly: Boolean = false): [Coupon!]!

  # Customer context (JWT required)
  me: Customer
  addresses(includeInactive: Boolean = false): [Address!]!
  orders(offset: Int!, limit: Int!, status: String): OrderCollection!
  order(id: ID!): Order
  refunds(offset: Int!, limit: Int!): RefundCollection!
}

type Mutation {
  login(input: LoginInput!): AuthPayload!
  signup(input: SignupInput!): AuthPayload!

  updateCart(input: CartUpdateInput!): CartPayload!
  applyCoupon(input: CouponInput!): CartPayload!
  removeCoupon(cartId: ID!): CartPayload!

  createAddress(input: AddressInput!): AddressPayload!
  updateAddress(input: AddressInput!): AddressPayload!
  deleteAddress(id: ID!): MutationStatus!

  checkout(input: CheckoutInput!): CheckoutPayload!
  requestRefund(input: RefundRequestInput!): RefundPayload!
}

interface Node {
  id: ID!
}

type ProductCollection {
  count: Int!
  items: [Product!]!
}

type Product {
  id: ID!
  styleCode: String
  sizeCode: String
  styleName: String
  colour: String
  group: String
  description: String
  keywords: String
  slug: String
  displayPrice: Float
  currentPrice: Float
  onSale: Boolean!
  isNew: Boolean!
  isNewUntil: ISO8601Date
  nextUseDate: ISO8601Date
  featured: Boolean!
  catalogueEcommId: ID
  catalogueId: ID
  categoryId: ID
  primeColor: ColorFilter
  secondColor: ColorFilter
  options: [Option!]!
  stocks: [ProductStock!]!
  price: Price
  benefits: [Benefit!]!
  imageUrls: [String!]!
}

type Cart {
  id: ID!
  items: [CartItem!]!
  total: Float!
  subtotal: Float!
  discount: Float!
  couponPercentage: Float
  couponDescription: String
  autoCoupon: Boolean
  customer: Customer
}

type CartItem {
  id: ID!
  quantity: Int!
  product: Product!
  totalPrice: Float!
}

type Customer {
  id: ID!
  email: String!
  firstName: String
  surname: String
  contactNumber: String
  createdAt: ISO8601DateTime!
}

type OrderCollection {
  count: Int!
  items: [Order!]!
}

type Order {
  id: ID!
  orderNumber: String
  orderStatus: String
  grandTotal: Float
  discountAmount: Float
  couponCode: String
  deliveryOptionName: String
  deliveryCost: Float
  createdAt: ISO8601DateTime!
  updatedAt: ISO8601DateTime!
  name: String
  surname: String
  phone: String
  email: String
  addressLine1: String
  addressLine2: String
  suburb: String
  city: String
  postalCode: String
  items: [OrderItem!]!
  transactions: [Transaction!]!
  refunds: [Refund!]!
}

type PaymentMethod {
  code: String!
  displayName: String!
  description: String
  supportsInstallments: Boolean!
}

type ShippingOption {
  code: String!
  displayName: String!
  estimateDays: Int
  cost: Float
  zone: Zone
}

type Coupon {
  id: ID!
  code: String!
  percentage: Int
  startDate: ISO8601Date
  endDate: ISO8601Date
  autoAddCoupon: Boolean
}

type RefundCollection {
  count: Int!
  items: [Refund!]!
}

type Refund {
  id: ID!
  firstName: String
  lastName: String
  contactNumber: String
  email: String
  line1: String
  line2: String
  suburb: String
  city: String
  createdAt: ISO8601DateTime!
  order: Order!
  items: [RefundItem!]!
}

type RefundItem {
  id: ID!
  reason: String
  action: String
  quantity: Int
  comment: String
  orderItem: OrderItem!
}

type Address {
  id: ID!
  line1: String
  line2: String
  suburb: String
  city: String
  province: String
  country: String
  postalCode: String
  isCurrent: Boolean
  createdAt: ISO8601DateTime!
  zone: Zone
}

type Zone {
  id: ID!
  zoneId: String
  suburb: String
  town: String
  province: String
  postalCode: String
  locationHub: String
  agentHub: String
  regional: Int
  township: Int
  surcharge: Int
  highRisk: Int
}

# Additional types omitted for brevity include ProductStock, Option, Benefit, Price, OrderItem, Transaction, etc.

input ProductFilterInput {
  catalogueEcommId: ID
  categoryId: ID
  optionIds: [ID!]
  colorIds: [ID!]
  featured: Boolean
  isNew: Boolean
  priceMin: Float
  priceMax: Float
}

input ProductSortInput {
  field: ProductSortField
  direction: SortDirection
}

enum ProductSortField {
  PRICE
  CREATED_AT
  STYLE_NAME
}

enum SortDirection {
  ASC
  DESC
}

input CartUpdateInput {
  cartId: ID
  items: [CartItemInput!]!
  couponCode: String
}

input CartItemInput {
  productId: ID!
  quantity: Int!
  sizeId: ID
}

input AddressInput {
  id: ID
  line1: String!
  line2: String
  suburb: String!
  city: String!
  province: String
  country: String
  postalCode: String!
  isCurrent: Boolean
}

input CheckoutInput {
  cartId: ID!
  paymentMethodCode: String!
  shippingOptionCode: String!
  address: AddressInput!
  notes: String
}

input LoginInput {
  email: String!
  password: String!
}

input SignupInput {
  email: String!
  password: String!
  firstName: String
  surname: String
  contactNumber: String
}

input CouponInput {
  cartId: ID!
  code: String!
}

input RefundRequestInput {
  orderId: ID!
  items: [RefundItemInput!]!
  firstName: String!
  lastName: String!
  contactNumber: String!
  email: String!
  line1: String
  line2: String
  suburb: String
  city: String
}

input RefundItemInput {
  orderItemId: ID!
  quantity: Int!
  reason: String!
  action: String!
  comment: String
}
```

> **Tip:** The real schema includes additional fields (`Benefit`, `Price`, `Transaction`, etc.) following the same naming conventions. Always consult `schema/schema.json` for automation or schema-first code generation.

---

## 11. Troubleshooting Matrix

| Symptom | Likely Cause | Mitigation |
| --- | --- | --- |
| `401 UNAUTHENTICATED` before GraphQL response | Missing/invalid `X-Client-Id` or `X-API-Key`, host/brand mismatch | Reissue headers, confirm brand binding, rotate key if leaked. |
| GraphQL error `UNAUTHENTICATED` inside payload | Missing/invalid bearer token | Prompt user login, refresh JWT. |
| `BAD_REQUEST` from controller | Invalid JSON body, missing `query`, non-POST, or wrong `Content-Type` | Validate client request formatting. |
| Mutation returns `success: false` with message | Business rule failure (coupon invalid, quantity mismatched) | Surface to user, correct payload. |
| `Invalid bearer token: ...` | JWT signature or format mismatch | Ensure HS256 and secret alignment; check token expiry. |
| Products list empty | Filters exclude all items, or brand’s catalogue empty | Adjust filter, confirm brand data import. |

---

## 12. Change Management Notes

- **API compatibility:** Schema carefully avoids breaking changes; nonetheless, monitor repository updates for new fields/arguments.
- **Rotation cadence:** Plan for quarterly API key rotation and automate distribution to avoid manual drift.
- **Metrics:** Consider instrumenting requests using the `correlationId` to tie GraphQL operations back to upstream actions.

---

## 13. Quick Start Script (Pseudo)

```python
import os, requests, uuid

HOST = os.environ["MEDICUS_BRAND_HOST"]
CLIENT_ID = os.environ["MEDICUS_CLIENT_ID"]
API_KEY = os.environ["MEDICUS_API_KEY"]
TOKEN = os.environ.get("MEDICUS_CUSTOMER_JWT")  # optional

payload = {
  "query": "query($offset:Int!, $limit:Int!){ products(offset:$offset, limit:$limit){ count items { id styleName currentPrice } } }",
  "variables": {"offset": 0, "limit": 5}
}

headers = {
  "Content-Type": "application/json",
  "X-Client-Id": CLIENT_ID,
  "X-API-Key": API_KEY,
  "X-Correlation-ID": str(uuid.uuid4())
}
if TOKEN:
  headers["Authorization"] = f"Bearer {TOKEN}"

response = requests.post(f"https://{HOST}/graphql", json=payload, headers=headers, timeout=10)
response.raise_for_status()
print(response.json())
```

---

## 14. Final Reminders

- Guard credentials: treat both API key and secret as privileged. Never embed in client-side code.
- Keep this document synchronized with codebase updates. When new queries/mutations ship, extend this guide before rolling credentials to external agents.
- Direct questions to the platform team mailer or create an issue referencing this guide version.

Good luck with your integration. Welcome to the hub.
