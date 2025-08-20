package net.a_cappella.madrigal.common.constants;

public interface MadrigalConstants {
	// the below types must match the ones in common-aeron/src/main/resources/schema.xml
	int TYPE_CREDENTIALS      = 1001;
	int TYPE_ECN_CREDENTIALS  = 1002;
	int TYPE_MARKET_STATUS    = 1003;
	int TYPE_ECN_INSTRUMENT   = 1004;
	int TYPE_ECN_INSTR_STATUS = 1005;
	int TYPE_ECN_IMBALANCE    = 1006;
	int TYPE_ECN_PRICE        = 1007;
	int TYPE_USR_STATUS       = 1008;
	int TYPE_ECN_USR_STATUS   = 1009;
	int TYPE_ORDER            = 1010;
	int TYPE_FINALIZE_ORDER   = 1011;
	int TYPE_MID_FEED         = 1012;

	String SUBJ_CREDENTIALS      = "credentials";
	String SUBJ_ECN_CREDENTIALS  = "ecn.credentials";
	String SUBJ_MARKET_STATUS    = "market.status";
	String SUBJ_ECN_INSTRUMENT   = "ecn.instrument";
	String SUBJ_ECN_INSTR_STATUS = "ecn.instr.status";
	String SUBJ_ECN_IMBALANCE    = "ecn.imbalance";
	String SUBJ_ECN_PRICE        = "ecn.price";
	String SUBJ_USR_STATUS       = "user.status";
	String SUBJ_ECN_USR_STATUS   = "ecn.user.status";
	String SUBJ_ORDER            = "order";
	String SUBJ_FINALIZE_ORDER   = "finalize.order";
	String SUBJ_MID_FEED         = "mid.feed";

    String FT_OMS_PREFIX = "FT.OMS.";
    String FT_USER_PREFIX = "FT.USER.";

    String VAL_ERR_STRING_NON_EXISTENT_ORDER = "Non existent order";
    String VAL_ERR_STRING_ALREADY_COMPLETED = "Order already completed";
    String VAL_ERR_STRING_TOO_LATE_TO_REPLACE = "Too late to replace";
    String VAL_ERR_STRING_ALREADY_EXISTS = "Order already exists";
    String VAL_ERR_STRING_DEL_ALREADY_SENT = "DEL already sent";
    String VAL_ERR_STRING_FAIL_FAST = "Fail Fast";
    String VAL_ERR_STRING_PENDING_DEL = "DEL pending";
    String VAL_ERR_STRING_RWT_NOT_SUPPORTED = "RWT not supported for IOC orders";
    String VAL_ERR_STRING_DEL_NOT_SUPPORTED = "DEL not supported for IOC orders";
    String VAL_ERR_STRING_SUPERSEDED = " superseded";
    String VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY = "residual less than min quantity";
    String VAL_EMPTY_STRING = "";

    String LH_ECN_PREFIX = "lh-";
}
