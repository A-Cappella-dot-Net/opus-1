package net.a_cappella.presto.ft.constants;

public enum FtMsgOp {
    NONE,
    REGISTER, UNREGISTER,                         // REQUESTs
    ACTIVATE, DEACTIVATE, DISCONNECT, DUPLICATE,  // RESPONSEs
    ;

    public static char toChar(FtMsgOp msgOp) {
        switch (msgOp) {
            case REGISTER:
                return 'R';
            case UNREGISTER:
                return 'U';
            case ACTIVATE:
                return '1';
            case DEACTIVATE:
                return '0';
            case DISCONNECT:
                return 'C';
            case DUPLICATE:
                return 'P';
            default:
                return '-';
        }
    }

    public static FtMsgOp toEnum(char msgOp) {
        switch (msgOp) {
            case 'R':
                return REGISTER;
            case 'U':
                return UNREGISTER;
            case '1':
                return ACTIVATE;
            case '0':
                return DEACTIVATE;
            case 'C':
                return DISCONNECT;
            case 'P':
                return DUPLICATE;
            default:
                return NONE;
        }
    }
}
