package project.init.framework.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.jwt")
public class JwtConfig {
    private int tokenValidityInSeconds;

    private String base64Secret;
    private String base64Public;

    private String clientId;

    public static final String ACCOUNT_CODE = "accountCode";
    public static final String ROLES = "roles";
    public final static String TOKEN_HEADER = "authorization";
    public static final String AZP = "azp";
    public static final String TRADER = "trader";
    public static final String STATUS = "status";
    public static final String AUTHORIZE = "authorize";
}
