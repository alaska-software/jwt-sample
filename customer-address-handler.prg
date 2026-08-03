//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// JWT example: REST handler that issues a token (POST /login) and verifies
/// the Bearer token on the protected /customers routes, guarding in-memory
/// customer-address data. Verify = :verify() (signature) + isValid() (exp).
/// See readme.md for the curl flow.
/// </summary>
///
/// <remarks>
/// Example only. In production split auth from business logic, load the
/// signing secret from configuration, and use a real user and data store.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////
#include "os.ch"

#define AUTH_SECRET   "my-256-bit-secret-key-change-me"
#define TOKEN_TTL     3600   // token lifetime in seconds (1 hour)


CLASS CustomerAddressHandler FROM RestHandler
   PROTECTED:
      METHOD authenticate()

   EXPORTED:
      CLASS METHOD onRegister()

      METHOD login( oCredentials )
      METHOD getAll()
      METHOD getById( nId )
      METHOD addCustomer( oData )
ENDCLASS


/// <summary>
/// Register routes and parameter types
/// </summary>
///
CLASS METHOD CustomerAddressHandler:onRegister(oEndpoint)
   UNUSED(oEndpoint)

   // path parameter ::id is cast to numeric before reaching getById()
   ::addType("id","N")

   // public: obtain a token
   ::map("POST", "/login",          "login")

   // protected: each method verifies the Bearer token itself
   ::map("GET",  "/customers",      "getAll")
   ::map("GET",  "/customers/::id", "getById")
   ::map("POST", "/customers",      "addCustomer")

   ::CrossOrigin:setOpenBackend()
RETURN self


/// <summary>
/// Authenticates the user and returns a signed JWT on success.
/// Public route - does not require a token.
/// </summary>
///
METHOD CustomerAddressHandler:login( oCredentials )
   LOCAL oPayload, oResult, cToken

   IF ValType(oCredentials) != "O" .OR. ;
      Empty(oCredentials:user) .OR. Empty(oCredentials:password)
      ::setError( 400, "user and password are required" )
      RETURN NIL
   ENDIF

   // Demo credential check - replace with a real user store / hashed
   // password comparison in production.
   IF !( oCredentials:user == "alice" .AND. oCredentials:password == "secret" )
      ::setError( 401, "Invalid credentials" )
      RETURN NIL
   ENDIF

   // Build the claims: who (sub) and how long the token is valid (exp).
   // toJSON() adds the issued-at "iat" claim automatically during encode().
   oPayload := JWTPayload():new()
   oPayload:setSubject( oCredentials:user )
   oPayload:setExpiration( UnixTime() + TOKEN_TTL )
   oPayload:setClaim( "role", "user" )

   cToken := JWT():new():encode( oPayload, "HS256", AUTH_SECRET )

   oResult := DataObject():new()
   oResult:token     := cToken
   oResult:tokenType := "Bearer"
   oResult:expiresIn := TOKEN_TTL
RETURN oResult


/// <summary>
/// Verifies the Bearer JWT from the Authorization header.
/// Returns the decoded JWTPayload on success, or NIL after setting an
/// appropriate 401 error.
/// </summary>
///
METHOD CustomerAddressHandler:authenticate()
   LOCAL cAuth, cToken, oJWT

   // Expect "Authorization: Bearer <token>"
   cAuth := ::HttpRequest:getHeader("Authorization")

   IF Empty(cAuth) .OR. Upper(Left(cAuth, 7)) != "BEARER "
      ::setError( 401, "Missing or malformed authorization header" )
      RETURN NIL
   ENDIF

   cToken := AllTrim( SubStr(cAuth, 8) )

   oJWT := JWT():new()

   // 1) signature must verify against our shared secret
   //    (a tampered token or an "alg":"none" token fails here)
   IF !oJWT:verify( cToken, AUTH_SECRET )
      ::setError( 401, "Invalid token signature" )
      RETURN NIL
   ENDIF

   // 2) token must decode and still be within its exp/nbf window
   IF !oJWT:decode( cToken ) .OR. !oJWT:getPayload():isValid()
      ::setError( 401, "Expired or not-yet-valid token" )
      RETURN NIL
   ENDIF

RETURN oJWT:getPayload()


/// <summary>
/// GET /customers - returns all customer addresses (requires a valid token)
/// </summary>
///
METHOD CustomerAddressHandler:getAll()
   IF ::authenticate() == NIL
      RETURN NIL   // 401 already set by authenticate()
   ENDIF
RETURN CustomerStore()


/// <summary>
/// GET /customers/::id - returns a single customer address by id
/// </summary>
///
METHOD CustomerAddressHandler:getById( nId )
   LOCAL oCustomer

   IF ::authenticate() == NIL
      RETURN NIL
   ENDIF

   oCustomer := FindCustomer( nId )
   IF oCustomer == NIL
      ::setError( 404, "Customer not found" )
      RETURN NIL
   ENDIF
RETURN oCustomer


/// <summary>
/// POST /customers - adds a customer address (kept in memory, no persistence)
/// </summary>
///
METHOD CustomerAddressHandler:addCustomer( oData )
   LOCAL aStore, oCustomer

   IF ::authenticate() == NIL
      RETURN NIL
   ENDIF

   IF ValType(oData) != "O" .OR. Empty(oData:name)
     ::setError( 400, "Customer name is required" )
      RETURN NIL
   ENDIF

   aStore    := CustomerStore()
   oCustomer := MakeCustomer( NextId(aStore), oData:name, ;
                              oData:city, oData:street, oData:zipCode )
   AAdd( aStore, oCustomer )
RETURN oCustomer


//=============================================================================
// In-memory customer-address store (fake data, no database)
//=============================================================================

/// <summary>
/// Returns the process-wide customer array, seeding it on first access.
/// New records added via POST live here for the lifetime of the process.
/// </summary>
///
STATIC FUNCTION CustomerStore()
   STATIC saStore := NIL

   IF saStore == NIL
      saStore := {}
      AAdd( saStore, MakeCustomer( 1, "Acme Corporation", "Berlin",  "Hauptstrasse 1",   "10115" ) )
      AAdd( saStore, MakeCustomer( 2, "Globex GmbH",      "Munich",  "Leopoldstrasse 12","80802" ) )
      AAdd( saStore, MakeCustomer( 3, "Initech AG",       "Hamburg", "Reeperbahn 5",     "20359" ) )
      AAdd( saStore, MakeCustomer( 4, "Umbrella Ltd",     "Cologne", "Domkloster 4",     "50667" ) )
      AAdd( saStore, MakeCustomer( 5, "Soylent KG",       "Dresden", "Pragerstrasse 7",  "01069" ) )
   ENDIF
RETURN saStore


STATIC FUNCTION MakeCustomer( nId, cName, cCity, cStreet, cZip )
   LOCAL oCustomer := DataObject():new()

   oCustomer:id      := nId
   oCustomer:name    := cName
   oCustomer:city    := cCity
   oCustomer:street  := cStreet
   oCustomer:zipCode := cZip
RETURN oCustomer


STATIC FUNCTION FindCustomer( nId )
   LOCAL aStore := CustomerStore()
   LOCAL nPos   := AScan( aStore, {|oCust| oCust:id == nId} )

   IF nPos == 0
      RETURN NIL
   ENDIF
RETURN aStore[nPos]


STATIC FUNCTION NextId( aStore )
   LOCAL nMax := 0
   LOCAL n

   FOR n := 1 TO Len(aStore)
      nMax := Max( nMax, aStore[n]:id )
   NEXT
RETURN nMax + 1
