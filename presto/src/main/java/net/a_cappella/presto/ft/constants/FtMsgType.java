package net.a_cappella.presto.ft.constants;

public enum FtMsgType {
    NONE, REQUEST, RESPONSE;

    public static char toChar(FtMsgType msgType) {
        switch (msgType) {
            case REQUEST:
                return 'Q';
            case RESPONSE:
                return 'P';
            default:
                return ' ';
        }
    }

    public static FtMsgType toEnum(char msgType) {
        switch (msgType) {
            case 'Q':
                return REQUEST;
            case 'P':
                return RESPONSE;
            default:
                return NONE;
        }
    }
}
