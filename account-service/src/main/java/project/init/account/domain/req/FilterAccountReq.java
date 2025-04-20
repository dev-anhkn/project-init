package project.init.account.domain.req;

import lombok.Data;

import java.util.List;

@Data
public class FilterAccountReq {
    private String accountCode;
    private String accountName;
    private List<String> roles;
    private String status;
    private int limit;
    private int offset;
}