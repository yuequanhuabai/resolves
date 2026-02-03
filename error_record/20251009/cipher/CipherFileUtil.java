package cn.bochk.pap.server.util;

import io.jsonwebtoken.io.IOException;

import java.io.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class CipherFileUtil {
    private static final String EOL = "\n";

    public static Map<String, String> readProperties(String propertiesPath) throws IOException {

        HashMap<String, String> passwordMap = new HashMap<>();
        Properties properties = null;
        try (BufferedReader reader = new BufferedReader(new FileReader(propertiesPath))) {
            properties = new Properties();
            properties.load(reader);

            for (String key : properties.stringPropertyNames()) {
                passwordMap.put(key, properties.getProperty(key));
            }
            return passwordMap;
        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        }
    }


    public static void writeSecreteKey(String secretKeyPath, String secretKeyStr) throws java.io.IOException {

        FileWriter fileWriter = null;
        BufferedWriter writer = null;
        File secretKeyFile = new File(secretKeyPath);


        try {
            if (!secretKeyFile.exists()) {
                createNewFile(secretKeyFile);
                fileWriter = new FileWriter(secretKeyFile);
                writer = new BufferedWriter(fileWriter);
                writer.write(secretKeyStr);
                writer.write(EOL);
            }
        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        } finally {
            if (null != writer) {
                writer.close();
            }
            if (null != fileWriter) {
                fileWriter.close();
            }
        }

    }




    public static void writeProperties(String propertiesPath, Map<String, String> passwordMap) throws java.io.IOException {
        FileWriter fileWriter = null;
        BufferedWriter writer = null;
        Properties properties;
        File propertiesFile;
        try {
            propertiesFile = new File(propertiesPath);
            fileWriter = new FileWriter(propertiesFile);
            writer = new BufferedWriter(fileWriter);
            properties = new Properties();
            for (String key : passwordMap.keySet()) {
                String value = passwordMap.get(key);
                properties.setProperty(key, value);
            }
            if (!propertiesFile.exists()) {
                createNewFile(propertiesFile);
            }
            properties.store(writer, null);

        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        } finally {
            if (writer != null) {
                writer.close();
            }
            if (fileWriter != null) {
                fileWriter.close();
            }
        }
    }


    public static void appendProperties(String propertiesPath, Map<String, String> passwordMap) throws java.io.IOException {
        FileWriter fileWriter = null;
        BufferedWriter writer = null;
        Properties properties;
        File propertiesFile;
        try {
            propertiesFile = new File(propertiesPath);
            fileWriter = new FileWriter(propertiesFile, true);
            writer = new BufferedWriter(fileWriter);
            properties = new Properties();
            for (String key : passwordMap.keySet()) {
                String value = passwordMap.get(key);
                properties.setProperty(key, value);
            }
            if (!propertiesFile.exists()) {
                createNewFile(propertiesFile);
            }
            properties.store(writer, null);

        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        } finally {
            if (writer != null) {
                writer.close();
            }
            if (fileWriter != null) {
                fileWriter.close();
            }
        }
    }


    public static void removeProperties(String propertiesPath, List<String> keys) throws java.io.IOException {
        FileReader fileReader = null;
        BufferedReader reader = null;
        FileWriter fileWriter = null;
        BufferedWriter writer = null;
        Properties properties = null;
        try {
            fileReader = new FileReader(propertiesPath);
            reader = new BufferedReader(fileReader);
            properties = new Properties();
            properties.load(reader);
            for (String key : keys) {
                properties.remove(key);
            }
            fileWriter = new FileWriter(new File(propertiesPath));
            writer = new BufferedWriter(fileWriter);
            properties.store(writer, null);
        } finally {
            if (writer != null) {
                writer.close();
            }
            if (fileWriter != null) {
                fileWriter.close();
            }
            if (reader != null) {
                reader.close();
            }
            if (fileReader != null) {
                fileReader.close();
            }
        }
    }


    public static String readSecretKey(String secretKeyPath) throws FileNotFoundException {
        String secretKeyStr;

        try (BufferedReader reader = new BufferedReader(new FileReader(secretKeyPath))) {
            String line;
            line = reader.readLine();
            if (line == null || line.trim().isEmpty()) {
                secretKeyStr = "";
            } else {
                secretKeyStr = line.trim();
            }
            return secretKeyStr;
        } catch (java.io.IOException e) {
            throw new RuntimeException(e);
        }

    }

    public static void createNewFile(File newFile) throws java.io.IOException {
        File parentFile = newFile.getParentFile();
        if (!parentFile.exists()) {
            parentFile.mkdirs();
        }
        newFile.createNewFile();
    }


}
