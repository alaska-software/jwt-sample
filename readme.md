# jwt-sample — JWT Authentication in Xbase++

A minimal Xbase++ microservice that demonstrates how to issue and verify
**JSON Web Tokens (JWT)** on a REST API built with the `jwt-helper` and
`rest-helper` assets.

The service exposes a small customer-address API on port **9000**:

| Method | Route             | Auth   | Purpose                          |
|--------|-------------------|--------|----------------------------------|
| POST   | `/login`          | public | exchange credentials for a token |
| GET    | `/customers`      | Bearer | list all customer addresses      |
| GET    | `/customers/::id` | Bearer | one customer address by id       |
| POST   | `/customers`      | Bearer | add an address (in-memory only)  |

Demo credentials are **`alice` / `secret`**.  
Everything runs in-process — no database, no external dependencies beyond the
Xbase++ assets listed in `project.xpj`.

---

## Checkout

```bat
git clone https://github.com/alaska-software/jwt-sample.git
cd jwt-sample
```

---

## Build and Run

**1. Install the required assets**

```bat
xppam PROJECT -install
```

**2. Build the executable**

```bat
pbuild
```

**3. Run the service**

```bat
cd run
custaddrsvc.exe -exe
```

The service starts on `http://localhost:9000`.

**Quick smoke-test with curl:**

```bat
REM obtain a token
curl -s -X POST http://localhost:9000/login ^
  -H "Content-Type: application/json" ^
  -d "{\"user\":\"alice\",\"password\":\"secret\"}"

REM call a protected route (paste the token from the response above)
curl -s http://localhost:9000/customers ^
  -H "Authorization: Bearer <token>"
```

---

## Learn More

For a full explanation of what JWTs are, how the two-step verification works
(`verify()` + `isValid()`), security best practices, and how to evolve this
sample into a production service, read the **jwt-helper guide**:

[JWT Guide — Alaska Software Documentation](https://guide.alaska-software.com/json-web-token-explained.html)
