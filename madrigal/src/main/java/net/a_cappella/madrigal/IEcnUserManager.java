package net.a_cappella.madrigal;

import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;

public interface IEcnUserManager {
    void publishEcnUserLogOpResponse(String ecnUid, MadrigalUserStatus status, String userStatusText);
}
