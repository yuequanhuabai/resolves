package cn.bochk.pap.server.util;

import javax.crypto.*;
import javax.crypto.spec.SecretKeySpec;
import java.io.FileNotFoundException;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Map;

public class AESUtil {

    public static String decrypt(String secretKeyStr, String ciphertextPw) throws Exception {
        try {
            String plaintextPw;
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            SecretKey secretKey = new SecretKeySpec(DatatypeConverter.parseHexBinary(secretKeyStr), "AES");

            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            byte[] decode = Base64.getDecoder().decode(ciphertextPw);
            byte[] doFinal2 = cipher.doFinal(decode);
            plaintextPw = new String(doFinal2, StandardCharsets.UTF_8);
            return plaintextPw;

        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | BadPaddingException |
                 IllegalBlockSizeException e) {
            throw new Exception(e);
        }
    }

    public static String encrypt(String secretKeyStr, String plaintextPw) {
        try {
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            SecretKey secretKey = new SecretKeySpec(DatatypeConverter.parseHexBinary(secretKeyStr), "AES");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            byte[] doFinal = cipher.doFinal(plaintextPw.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(doFinal);
        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | IllegalAccessException |
                 IllegalBlockSizeException | BadPaddingException e) {
            throw new RuntimeException(e);
        }
    }

    public static String generateSecretKey() throws NoSuchAlgorithmException {
        KeyGenerator keyGenerator;
        keyGenerator = KeyGenerator.getInstance("AES");
        keyGenerator.init(128);
        SecretKey secretKey = keyGenerator.generateKey();
        return DatatypeConverter.printHexBinary(secretKey.getEncoded());
    }

    public static String queryPasswordByKey(String secretKeyPath, String passwordAlias, String ciphertextPwProperties) throws Exception {
        Map<String, String> ciphertextPwMap = null;
        String secretKeyStr = CipherFileUtil.readSecretKey(secretKeyPath);
        ciphertextPwMap = CipherFileUtil.readProperties(ciphertextPwProperties);
        for (String key : ciphertextPwMap.keySet()) {
            if (passwordAlias.equals(key)) {
                return decrypt(secretKeyStr, ciphertextPwMap.get(key));
            }
        }
        return "";
    }
}
