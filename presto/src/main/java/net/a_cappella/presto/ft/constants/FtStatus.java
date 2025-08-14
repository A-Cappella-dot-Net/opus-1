package net.a_cappella.presto.ft.constants;

public enum FtStatus {
    UNINITIALIZED, ACTIVE, INACTIVE;

    public static char toChar(FtStatus ftStatus) {
        switch (ftStatus) {
            case ACTIVE:
                return 'A';
            case INACTIVE:
                return 'I';
            default:
                return 'U';
        }
    }

    public static FtStatus toEnum(char ftStatus) {
        switch (ftStatus) {
            case 'A':
                return ACTIVE;
            case 'I':
                return INACTIVE;
            default:
                return UNINITIALIZED;
        }
    }
}
