package cn.bochk.pap;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Batch create approval test users (p001~p010) via REST API.
 *
 * - Reference role: approve (copies its menu permissions & data scope to new role test_approve)
 * - Reference user: approve001 (copies its dept & post to new users)
 *
 * Run this class directly from IDE (main method).
 * Requires the backend server to be running.
 */
public class BatchApproveUserCreator {

    // ==================== Configuration ====================
    private static final String BASE_URL = "http://localhost:9600";
    private static final String ADMIN_USERNAME = "admin";
    private static final String ADMIN_PASSWORD = "admin";

    private static final String REFERENCE_ROLE_CODE = "approve";        // 参考角色标识（审批）
    private static final String NEW_ROLE_NAME = "test_approve";         // 新角色名称
    private static final String NEW_ROLE_CODE = "test_approve";         // 新角色标识
    private static final int NEW_ROLE_SORT = 100;                       // 新角色排序

    private static final String REFERENCE_USERNAME = "approve001";      // 参考用户（获取部门/岗位）
    private static final String USER_PREFIX = "p";                      // 用户名前缀
    private static final int USER_START = 1;                            // 起始编号
    private static final int USER_COUNT = 10;                           // 创建数量
    private static final String USER_PASSWORD = "123456";               // 统一密码
    // ========================================================

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper = new ObjectMapper();
    private String accessToken;

    public static void main(String[] args) throws Exception {
        new BatchApproveUserCreator().run();
    }

    private void run() throws Exception {
        // Step 1: Login
        System.out.println("=== Step 1: Login as admin ===");
        login();

        // Step 2: Find reference role "approve"
        System.out.println("\n=== Step 2: Find reference role (code=" + REFERENCE_ROLE_CODE + ") ===");
        long refRoleId = findRoleByCode(REFERENCE_ROLE_CODE);
        System.out.println("Found role ID: " + refRoleId);

        // Step 3: Get menu permissions of reference role
        System.out.println("\n=== Step 3: Get menu permissions ===");
        Set<Long> menuIds = getRoleMenuIds(refRoleId);
        System.out.println("Menu IDs count: " + menuIds.size());

        // Step 4: Get role detail (dataScope)
        System.out.println("\n=== Step 4: Get role detail (dataScope) ===");
        JsonNode roleDetail = getRoleDetail(refRoleId);
        int dataScope = roleDetail.get("dataScope").asInt();
        Set<Long> dataScopeDeptIds = new HashSet<>();
        JsonNode deptIdsNode = roleDetail.get("dataScopeDeptIds");
        if (deptIdsNode != null && deptIdsNode.isArray()) {
            for (JsonNode id : deptIdsNode) {
                dataScopeDeptIds.add(id.asLong());
            }
        }
        System.out.println("dataScope: " + dataScope + ", dataScopeDeptIds: " + dataScopeDeptIds);

        // Step 5: Find reference user approve001
        System.out.println("\n=== Step 5: Find reference user (" + REFERENCE_USERNAME + ") ===");
        JsonNode refUser = findUserByUsername(REFERENCE_USERNAME);
        System.out.println("Raw reference user data: " + refUser);
        JsonNode deptIdNode = refUser.get("deptId");
        Long deptId = (deptIdNode != null && !deptIdNode.isNull()) ? deptIdNode.asLong() : null;
        Set<Long> postIds = new HashSet<>();
        JsonNode postIdsNode = refUser.get("postIds");
        if (postIdsNode != null && postIdsNode.isArray()) {
            for (JsonNode id : postIdsNode) {
                if (!id.isNull()) {
                    postIds.add(id.asLong());
                }
            }
        }
        System.out.println("deptId: " + deptId + ", postIds: " + postIds);

        // Step 6: Create new role test_approve
        System.out.println("\n=== Step 6: Create role '" + NEW_ROLE_CODE + "' ===");
        long newRoleId = createRole();
        System.out.println("Created role ID: " + newRoleId);

        // Step 7: Assign menu permissions
        System.out.println("\n=== Step 7: Assign menu permissions to new role ===");
        assignRoleMenu(newRoleId, menuIds);
        System.out.println("Menu permissions assigned.");

        // Step 8: Assign data scope
        System.out.println("\n=== Step 8: Assign data scope to new role ===");
        assignRoleDataScope(newRoleId, dataScope, dataScopeDeptIds);
        System.out.println("Data scope assigned.");

        // Step 9: Batch create users
        System.out.println("\n=== Step 9: Batch create users ===");
        List<String> createdUsers = new ArrayList<>();
        List<String> skippedUsers = new ArrayList<>();
        for (int i = USER_START; i < USER_START + USER_COUNT; i++) {
            String username = USER_PREFIX + String.format("%03d", i);
            System.out.print("  Creating user: " + username + " ... ");

            // Check if user already exists
            JsonNode existing = findUserByUsernameOrNull(username);
            if (existing != null) {
                System.out.println("SKIPPED (already exists, id=" + existing.get("id").asLong() + ")");
                // Still assign role in case it's missing
                long userId = existing.get("id").asLong();
                assignUserRole(userId, newRoleId);
                skippedUsers.add(username);
                continue;
            }

            // Create user
            long userId = createUser(username, username, deptId, postIds);
            System.out.print("created (id=" + userId + ") ... ");

            // Assign role
            assignUserRole(userId, newRoleId);
            System.out.println("role assigned.");
            createdUsers.add(username);
        }

        // Step 10: Summary
        System.out.println("\n========== SUMMARY ==========");
        System.out.println("Role created: " + NEW_ROLE_CODE + " (id=" + newRoleId + ")");
        System.out.println("  - Copied " + menuIds.size() + " menu permissions from role '" + REFERENCE_ROLE_CODE + "'");
        System.out.println("  - dataScope=" + dataScope);
        System.out.println("Users created: " + createdUsers.size());
        if (!createdUsers.isEmpty()) {
            System.out.println("  " + createdUsers);
        }
        if (!skippedUsers.isEmpty()) {
            System.out.println("Users skipped (already existed): " + skippedUsers.size());
            System.out.println("  " + skippedUsers);
        }
        System.out.println("Password for all users: " + USER_PASSWORD);
        System.out.println("=============================");
    }

    // ==================== API Methods ====================

    private void login() throws Exception {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("username", ADMIN_USERNAME);
        body.put("password", ADMIN_PASSWORD);

        JsonNode data = post("/admin-api/system/auth/login", body);
        accessToken = data.get("accessToken").asText();
        System.out.println("Login successful. Token: " + accessToken.substring(0, Math.min(20, accessToken.length())) + "...");
    }

    private long findRoleByCode(String code) throws Exception {
        JsonNode data = get("/admin-api/system/role/page?pageSize=100&pageNo=1");
        JsonNode list = data.get("list");
        for (JsonNode role : list) {
            if (code.equals(role.get("code").asText())) {
                return role.get("id").asLong();
            }
        }
        throw new RuntimeException("Role with code '" + code + "' not found!");
    }

    private Set<Long> getRoleMenuIds(long roleId) throws Exception {
        JsonNode data = get("/admin-api/system/permission/list-role-menus?roleId=" + roleId);
        Set<Long> ids = new HashSet<>();
        if (data.isArray()) {
            for (JsonNode id : data) {
                ids.add(id.asLong());
            }
        }
        return ids;
    }

    private JsonNode getRoleDetail(long roleId) throws Exception {
        return get("/admin-api/system/role/get?id=" + roleId);
    }

    private JsonNode findUserByUsername(String username) throws Exception {
        JsonNode data = get("/admin-api/system/user/page?pageSize=10&pageNo=1&username=" + username);
        JsonNode list = data.get("list");
        for (JsonNode user : list) {
            if (username.equals(user.get("username").asText())) {
                return user;
            }
        }
        throw new RuntimeException("User '" + username + "' not found!");
    }

    private JsonNode findUserByUsernameOrNull(String username) throws Exception {
        JsonNode data = get("/admin-api/system/user/page?pageSize=10&pageNo=1&username=" + username);
        JsonNode list = data.get("list");
        for (JsonNode user : list) {
            if (username.equals(user.get("username").asText())) {
                return user;
            }
        }
        return null;
    }

    private long createRole() throws Exception {
        // Check if role already exists
        JsonNode pageData = get("/admin-api/system/role/page?pageSize=100&pageNo=1&code=" + NEW_ROLE_CODE);
        JsonNode list = pageData.get("list");
        for (JsonNode role : list) {
            if (NEW_ROLE_CODE.equals(role.get("code").asText())) {
                System.out.println("  Role '" + NEW_ROLE_CODE + "' already exists (id=" + role.get("id").asLong() + "), reusing.");
                return role.get("id").asLong();
            }
        }

        ObjectNode body = objectMapper.createObjectNode();
        body.put("name", NEW_ROLE_NAME);
        body.put("code", NEW_ROLE_CODE);
        body.put("sort", NEW_ROLE_SORT);
        body.put("status", 0); // 0 = enabled
        body.put("remark", "Auto-created for approval load testing");

        JsonNode data = post("/admin-api/system/role/create", body);
        return data.asLong();
    }

    private void assignRoleMenu(long roleId, Set<Long> menuIds) throws Exception {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("roleId", roleId);
        ArrayNode menuArray = body.putArray("menuIds");
        for (Long id : menuIds) {
            menuArray.add(id);
        }
        post("/admin-api/system/permission/assign-role-menu", body);
    }

    private void assignRoleDataScope(long roleId, int dataScope, Set<Long> dataScopeDeptIds) throws Exception {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("roleId", roleId);
        body.put("dataScope", dataScope);
        ArrayNode deptArray = body.putArray("dataScopeDeptIds");
        for (Long id : dataScopeDeptIds) {
            deptArray.add(id);
        }
        post("/admin-api/system/permission/assign-role-data-scope", body);
    }

    private long createUser(String username, String nickname, Long deptId, Set<Long> postIds) throws Exception {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("username", username);
        body.put("nickname", nickname);
        body.put("password", USER_PASSWORD);
        if (deptId != null) {
            body.put("deptId", deptId);
        }
        body.put("status", 0); // 0 = enabled
        if (postIds != null && !postIds.isEmpty()) {
            ArrayNode postArray = body.putArray("postIds");
            for (Long id : postIds) {
                postArray.add(id);
            }
        }

        JsonNode data = post("/admin-api/system/user/create", body);
        return data.asLong();
    }

    private void assignUserRole(long userId, long roleId) throws Exception {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("userId", userId);
        ArrayNode roleArray = body.putArray("roleIds");
        roleArray.add(roleId);
        post("/admin-api/system/permission/assign-user-role", body);
    }

    // ==================== HTTP Helpers ====================

    private JsonNode get(String path) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .GET()
                .header("Content-Type", "application/json");
        if (accessToken != null) {
            builder.header("Authorization", "Bearer " + accessToken);
        }

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        return parseResponse(response, path);
    }

    private JsonNode post(String path, ObjectNode body) throws Exception {
        String jsonBody = objectMapper.writeValueAsString(body);
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                .header("Content-Type", "application/json");
        if (accessToken != null) {
            builder.header("Authorization", "Bearer " + accessToken);
        }

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        return parseResponse(response, path);
    }

    private JsonNode parseResponse(HttpResponse<String> response, String path) throws Exception {
        if (response.statusCode() != 200) {
            throw new RuntimeException("HTTP " + response.statusCode() + " for " + path + ": " + response.body());
        }

        JsonNode root = objectMapper.readTree(response.body());
        int code = root.get("code").asInt();
        if (code != 0) {
            String msg = root.has("msg") ? root.get("msg").asText() : "unknown error";
            throw new RuntimeException("API error (code=" + code + ") for " + path + ": " + msg);
        }

        return root.get("data");
    }
}
