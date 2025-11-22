
> 好的，幫我設計一下 oauth2-common

● 好的，我幫你設計 oauth2-common 的結構。讓我詳細規劃一下這個工具庫應該包含什麼。

● oauth2-common 完整設計

項目結構

oauth2-common/
├── pom.xml
├── src/main/java/com/oauth2/
│   ├── jwt/                          # JWT 相關
│   │   ├── JwtProvider.java          # JWT 生成器
│   │   ├── JwtValidator.java         # JWT 驗證器
│   │   ├── JwtPayload.java           # JWT 載荷 DTO
│   │   └── JwtException.java         # 異常類
│   │
│   ├── token/                        # Token 相關
│   │   ├── TokenGenerator.java       # Token 生成器
│   │   ├── AccessToken.java          # AccessToken DTO
│   │   ├── RefreshToken.java         # RefreshToken DTO
│   │   └── TokenType.java            # Token 類型枚舉
│   │
│   ├── crypto/                       # 加密解密
│   │   ├── CryptoUtil.java           # 加密工具（對稱加密）
│   │   ├── HashUtil.java             # 哈希工具（密碼加密）
│   │   └── RsaKeyPair.java           # RSA 密鑰對
│   │
│   ├── constant/                     # 常量
│   │   ├── OAuthConstants.java       # OAuth 常量
│   │   ├── ClaimNames.java           # JWT claim 名稱
│   │   └── ErrorCode.java            # 錯誤碼
│   │
│   ├── dto/                          # 數據傳輸對象
│   │   ├── AuthorizationRequest.java
│   │   ├── TokenRequest.java
│   │   ├── TokenResponse.java
│   │   ├── UserInfoResponse.java
│   │   └── ErrorResponse.java
│   │
│   └── utils/                        # 工具類
│       ├── StringUtil.java
│       ├── TimeUtil.java
│       └── ValidationUtil.java
│
└── src/test/java/com/oauth2/
├── jwt/
├── token/
├── crypto/
└── ...

  ---
詳細的類設計

1?? JWT 相關

JwtPayload.java - JWT 載荷對象

public class JwtPayload {
private String iss;              // 發行者 (issuer)
private String sub;              // 主體 (subject - 用戶ID)
private String aud;              // 受眾 (audience - client_id)
private long exp;                // 過期時間 (expiration time)
private long iat;                // 簽發時間 (issued at)
private String nonce;            // 隨機數（用於 OIDC）
private long authTime;           // 認證時間
private String scope;            // 權限范圍

      // 額外的用戶信息（用於 ID Token）
      private String name;
      private String email;
      private boolean emailVerified;

      // Getters and Setters
}

JwtProvider.java - JWT 生成器

public class JwtProvider {
private final String privateKey;      // RSA 私鑰
private final String issuer;          // 發行者 URL
private final int expirationSeconds;  // 過期秒數

      /**
       * 生成 JWT Token
       */
      public String generateToken(JwtPayload payload) {
          long now = System.currentTimeMillis();
          long expiration = now + (expirationSeconds * 1000L);

          Claims claims = Jwts.claims()
              .setIssuer(issuer)
              .setSubject(payload.getSub())
              .setAudience(payload.getAud())
              .setIssuedAt(new Date(now))
              .setExpiration(new Date(expiration));

          // 添加自定義 claims
          claims.put("nonce", payload.getNonce());
          claims.put("auth_time", payload.getAuthTime());
          claims.put("scope", payload.getScope());
          claims.put("name", payload.getName());
          claims.put("email", payload.getEmail());
          claims.put("email_verified", payload.isEmailVerified());

          return Jwts.builder()
              .setClaims(claims)
              .signWith(getPrivateKey(), SignatureAlgorithm.RS256)
              .compact();
      }

      /**
       * 生成 ID Token（OIDC 專用）
       */
      public String generateIdToken(String userId, String clientId, String nonce,
                                     String name, String email) {
          JwtPayload payload = new JwtPayload();
          payload.setSub(userId);
          payload.setAud(clientId);
          payload.setNonce(nonce);
          payload.setAuthTime(System.currentTimeMillis() / 1000);
          payload.setName(name);
          payload.setEmail(email);
          payload.setEmailVerified(true);

          return generateToken(payload);
      }

      /**
       * 生成 Access Token
       */
      public String generateAccessToken(String userId, String clientId, String scope) {
          JwtPayload payload = new JwtPayload();
          payload.setSub(userId);
          payload.setAud(clientId);
          payload.setScope(scope);
          payload.setAuthTime(System.currentTimeMillis() / 1000);

          return generateToken(payload);
      }
}

JwtValidator.java - JWT 驗證器

public class JwtValidator {
private final String publicKey;   // RSA 公鑰
private final String issuer;      // 預期的發行者

      /**
       * 驗證並解析 JWT
       */
      public JwtPayload validateAndParse(String token) throws JwtException {
          try {
              Claims claims = Jwts.parserBuilder()
                  .setSigningKey(getPublicKey())
                  .build()
                  .parseClaimsJws(token)
                  .getBody();

              // 驗證 issuer
              if (!claims.getIssuer().equals(issuer)) {
                  throw new JwtException("Invalid issuer");
              }

              // 驗證是否過期（實際上 JWT 庫會自動檢查）
              if (claims.getExpiration().before(new Date())) {
                  throw new JwtException("Token expired");
              }

              return parseClaimsToPayload(claims);
          } catch (JwtException e) {
              throw new JwtException("Invalid token: " + e.getMessage());
          }
      }

      /**
       * 驗證 nonce
       */
      public void validateNonce(String token, String expectedNonce) throws JwtException {
          JwtPayload payload = validateAndParse(token);
          if (!payload.getNonce().equals(expectedNonce)) {
              throw new JwtException("Nonce mismatch");
          }
      }

      /**
       * 驗證 audience (client_id)
       */
      public void validateAudience(String token, String expectedClientId) throws JwtException {
          JwtPayload payload = validateAndParse(token);
          if (!payload.getAud().equals(expectedClientId)) {
              throw new JwtException("Audience mismatch");
          }
      }

      private JwtPayload parseClaimsToPayload(Claims claims) {
          JwtPayload payload = new JwtPayload();
          payload.setIss(claims.getIssuer());
          payload.setSub(claims.getSubject());
          payload.setAud(claims.getAudience());
          payload.setExp(claims.getExpiration().getTime() / 1000);
          payload.setIat(claims.getIssuedAt().getTime() / 1000);
          payload.setNonce((String) claims.get("nonce"));
          payload.setAuthTime(((Number) claims.get("auth_time")).longValue());
          payload.setScope((String) claims.get("scope"));
          payload.setName((String) claims.get("name"));
          payload.setEmail((String) claims.get("email"));
          payload.setEmailVerified((boolean) claims.get("email_verified"));
          return payload;
      }
}

  ---
2?? Token 相關

TokenGenerator.java - Token 生成器

public class TokenGenerator {
/**
* 生成隨機 access_token（不是 JWT，只是隨機字符串）
*/
public String generateAccessToken() {
return generateRandomToken(256);
}

      /**
       * 生成隨機 refresh_token
       */
      public String generateRefreshToken() {
          return generateRandomToken(256);
      }

      /**
       * 生成授權碼 (authorization code)
       */
      public String generateAuthorizationCode() {
          return generateRandomToken(128);
      }

      /**
       * 生成隨機 state (CSRF 防護)
       */
      public String generateState() {
          return generateRandomToken(64);
      }

      /**
       * 生成隨機 nonce (防止重放攻擊)
       */
      public String generateNonce() {
          return generateRandomToken(32);
      }

      private String generateRandomToken(int length) {
          SecureRandom random = new SecureRandom();
          byte[] bytes = new byte[length];
          random.nextBytes(bytes);
          return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
      }
}

AccessToken.java

public class AccessToken {
private String token;
private String tokenType;        // "Bearer"
private long expiresIn;          // 過期秒數
private String scope;

      // Getters and Setters
}

  ---
3?? 加密相關

HashUtil.java - 密碼加密

public class HashUtil {
private static final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

      /**
       * 加密密碼
       */
      public static String hashPassword(String rawPassword) {
          return encoder.encode(rawPassword);
      }

      /**
       * 驗證密碼
       */
      public static boolean matchPassword(String rawPassword, String hashedPassword) {
          return encoder.matches(rawPassword, hashedPassword);
      }

      /**
       * 生成 SHA-256 雜湊（用於加密 token 存儲）
       */
      public static String sha256(String input) {
          try {
              MessageDigest digest = MessageDigest.getInstance("SHA-256");
              byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
              return Base64.getEncoder().encodeToString(hash);
          } catch (NoSuchAlgorithmException e) {
              throw new RuntimeException("SHA-256 not available", e);
          }
      }
}

CryptoUtil.java - 對稱加密

public class CryptoUtil {
private final String encryptionKey;  // 對稱加密密鑰

      /**
       * 加密字符串
       */
      public String encrypt(String plainText) {
          try {
              Cipher cipher = Cipher.getInstance("AES");
              SecretKey secretKey = new SecretKeySpec(
                  encryptionKey.getBytes(StandardCharsets.UTF_8),
                  0, 16, "AES"
              );
              cipher.init(Cipher.ENCRYPT_MODE, secretKey);
              byte[] encryptedBytes = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));
              return Base64.getEncoder().encodeToString(encryptedBytes);
          } catch (Exception e) {
              throw new RuntimeException("Encryption failed", e);
          }
      }

      /**
       * 解密字符串
       */
      public String decrypt(String encryptedText) {
          try {
              Cipher cipher = Cipher.getInstance("AES");
              SecretKey secretKey = new SecretKeySpec(
                  encryptionKey.getBytes(StandardCharsets.UTF_8),
                  0, 16, "AES"
              );
              cipher.init(Cipher.DECRYPT_MODE, secretKey);
              byte[] decryptedBytes = cipher.doFinal(Base64.getDecoder().decode(encryptedText));
              return new String(decryptedBytes, StandardCharsets.UTF_8);
          } catch (Exception e) {
              throw new RuntimeException("Decryption failed", e);
          }
      }
}

  ---
4?? 常量

OAuthConstants.java

public class OAuthConstants {
// Scope
public static final String SCOPE_READ = "read";
public static final String SCOPE_WRITE = "write";
public static final String SCOPE_OPENID = "openid";
public static final String SCOPE_PROFILE = "profile";
public static final String SCOPE_EMAIL = "email";

      // Response Type
      public static final String RESPONSE_TYPE_CODE = "code";
      public static final String RESPONSE_TYPE_TOKEN = "token";

      // Grant Type
      public static final String GRANT_TYPE_AUTHORIZATION_CODE = "authorization_code";
      public static final String GRANT_TYPE_REFRESH_TOKEN = "refresh_token";

      // Token Type
      public static final String TOKEN_TYPE_BEARER = "Bearer";

      // Error Codes
      public static final String ERROR_INVALID_REQUEST = "invalid_request";
      public static final String ERROR_INVALID_CLIENT = "invalid_client";
      public static final String ERROR_INVALID_GRANT = "invalid_grant";
      public static final String ERROR_INVALID_SCOPE = "invalid_scope";
      public static final String ERROR_UNAUTHORIZED_CLIENT = "unauthorized_client";
      public static final String ERROR_UNSUPPORTED_GRANT_TYPE = "unsupported_grant_type";
      public static final String ERROR_UNSUPPORTED_RESPONSE_TYPE = "unsupported_response_type";
      public static final String ERROR_SERVER_ERROR = "server_error";
      public static final String ERROR_TEMPORARILY_UNAVAILABLE = "temporarily_unavailable";
      public static final String ERROR_ACCESS_DENIED = "access_denied";

      // Expiration Times (in seconds)
      public static final int AUTHORIZATION_CODE_EXPIRATION = 600;      // 10 minutes
      public static final int ACCESS_TOKEN_EXPIRATION = 3600;           // 1 hour
      public static final int REFRESH_TOKEN_EXPIRATION = 2592000;       // 30 days
}

ClaimNames.java

public class ClaimNames {
// Standard Claims
public static final String ISS = "iss";
public static final String SUB = "sub";
public static final String AUD = "aud";
public static final String EXP = "exp";
public static final String IAT = "iat";
public static final String NBF = "nbf";

      // Custom Claims for OIDC
      public static final String NONCE = "nonce";
      public static final String AUTH_TIME = "auth_time";
      public static final String SCOPE = "scope";
      public static final String CLIENT_ID = "client_id";

      // User Info Claims
      public static final String NAME = "name";
      public static final String EMAIL = "email";
      public static final String EMAIL_VERIFIED = "email_verified";
      public static final String PICTURE = "picture";
      public static final String PHONE = "phone";
}

  ---
5?? DTO 對象

TokenResponse.java - Token 端點返回

public class TokenResponse {
@JsonProperty("access_token")
private String accessToken;

      @JsonProperty("token_type")
      private String tokenType;

      @JsonProperty("expires_in")
      private long expiresIn;

      @JsonProperty("refresh_token")
      private String refreshToken;

      @JsonProperty("id_token")
      private String idToken;        // OIDC 特有

      @JsonProperty("scope")
      private String scope;

      // Getters and Setters
}

ErrorResponse.java - 錯誤返回

public class ErrorResponse {
private String error;
private String errorDescription;
private String errorUri;
private String state;

      public ErrorResponse(String error, String errorDescription) {
          this.error = error;
          this.errorDescription = errorDescription;
      }

      // Getters and Setters
}

UserInfoResponse.java - UserInfo 端點返回

public class UserInfoResponse {
private String sub;
private String name;
private String email;

      @JsonProperty("email_verified")
      private boolean emailVerified;

      private String picture;

      // Getters and Setters
}

  ---
6?? 工具類

ValidationUtil.java - 驗證工具

public class ValidationUtil {
/**
* 驗證 redirect_uri 格式
*/
public static boolean isValidRedirectUri(String uri) {
try {
new URL(uri);
return uri.startsWith("http://") || uri.startsWith("https://");
} catch (MalformedURLException e) {
return false;
}
}

      /**
       * 驗證 client_id 格式
       */
      public static boolean isValidClientId(String clientId) {
          return clientId != null && clientId.matches("[a-zA-Z0-9_-]+");
      }

      /**
       * 驗證 scope 格式
       */
      public static boolean isValidScope(String scope) {
          return scope != null && !scope.isEmpty();
      }
}

TimeUtil.java - 時間工具

public class TimeUtil {
/**
* 獲取當前時間戳（秒）
*/
public static long getCurrentTimestamp() {
return System.currentTimeMillis() / 1000;
}

      /**
       * 計算過期時間（秒）
       */
      public static long getExpirationTime(long expirationSeconds) {
          return getCurrentTimestamp() + expirationSeconds;
      }

      /**
       * 檢查是否已過期
       */
      public static boolean isExpired(long expirationTime) {
          return expirationTime < getCurrentTimestamp();
      }
}

  ---
pom.xml 依賴

  <?xml version="1.0" encoding="UTF-8"?>
  <project xmlns="http://maven.apache.org/POM/4.0.0">
      <modelVersion>4.0.0</modelVersion>

      <groupId>com.oauth2</groupId>
      <artifactId>oauth2-common</artifactId>
      <version>1.0.0</version>
      <packaging>jar</packaging>

      <properties>
          <java.version>17</java.version>
          <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
          <jwt.version>0.12.3</jwt.version>
      </properties>

      <dependencies>
          <!-- JWT -->
          <dependency>
              <groupId>io.jsonwebtoken</groupId>
              <artifactId>jjwt-api</artifactId>
              <version>${jwt.version}</version>
          </dependency>
          <dependency>
              <groupId>io.jsonwebtoken</groupId>
              <artifactId>jjwt-impl</artifactId>
              <version>${jwt.version}</version>
              <scope>runtime</scope>
          </dependency>
          <dependency>
              <groupId>io.jsonwebtoken</groupId>
              <artifactId>jjwt-jackson</artifactId>
              <version>${jwt.version}</version>
              <scope>runtime</scope>
          </dependency>

          <!-- Spring Security for password encoding -->
          <dependency>
              <groupId>org.springframework.security</groupId>
              <artifactId>spring-security-crypto</artifactId>
              <version>6.1.0</version>
          </dependency>

          <!-- Lombok -->
          <dependency>
              <groupId>org.projectlombok</groupId>
              <artifactId>lombok</artifactId>
              <version>1.18.30</version>
              <optional>true</optional>
          </dependency>

          <!-- Jackson -->
          <dependency>
              <groupId>com.fasterxml.jackson.core</groupId>
              <artifactId>jackson-databind</artifactId>
              <version>2.16.0</version>
          </dependency>

          <!-- JUnit 5 for testing -->
          <dependency>
              <groupId>org.junit.jupiter</groupId>
              <artifactId>junit-jupiter</artifactId>
              <version>5.9.2</version>
              <scope>test</scope>
          </dependency>
      </dependencies>
  </project>

  ---
總結

這個 oauth2-common 庫包含了：

? JWT 生成和驗證 - JwtProvider, JwtValidator
? Token 生成 - TokenGenerator
? 加密工具 - HashUtil, CryptoUtil
? 常量定義 - OAuthConstants, ClaimNames
? DTO 對象 - TokenResponse, ErrorResponse, UserInfoResponse
? 驗證工具 - ValidationUtil
? 時間工具 - TimeUtil

兩個後端都可以引入這個庫來使用這些工具。

怎麼樣，這個設計可以嗎？還是想調整一些地方？