package cn.bochk.pap.server.business.dal;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@TableName("ASSET_TYPE")
@Data
public class AssetTypeDo {

    private String id;

    private String customerTierId;

    private String assetType;

    private String systemCode;

    private String buyList;

    private String field;

    private String houseViewList;

    /**
     * 获取完整的 BR_SECURITY_MASTER_ 表名
     * @return 例如：BR_SECURITY_MASTER__BND
     */
    public String getSecurityMasterTableName() {
        return "BR_SECURITY_MASTER_" + systemCode;
    }
}
