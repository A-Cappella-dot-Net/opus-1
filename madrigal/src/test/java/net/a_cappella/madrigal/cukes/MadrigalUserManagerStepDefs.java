package net.a_cappella.madrigal.cukes;

import io.cucumber.java.After;
import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.common.obj.CredentialsObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.cukes.adaptors.um.*;
import net.a_cappella.madrigal.user.MadrigalUserManager;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

public class MadrigalUserManagerStepDefs {
    private static final Logger log = LoggerFactory.getLogger(MadrigalUserManagerStepDefs.class);
	
	private ServiceAndPublishedObjects[] _servicesAndPublishedObjects;

	private static class ServiceAndPublishedObjects {
		private final MadrigalUserManager _service;
		private final List<Obj> _publishedObjects = new ArrayList<>();
		
		public ServiceAndPublishedObjects(PrestoClient client) {
			_service = new MadrigalUserManager(client);
		}
	}

	private String toStr(UserStatusObj o) {
		return "{"+
				o.getUid()+" "+o.getClId()+" "+o.getOp()+" "+
				((REQUEST==o.getMadrigalMode())?(o.isRejectIfLoggedIn()+" "+o.isForceLogout()):(o.getStatus()+" "+o.getReqStatus()+" "+o.getText()))+
				"}";
	}


	@Before
	public void before() {
	}
	@After
	public void after() {
		if (_servicesAndPublishedObjects!=null) {
			for (int i=0; i<_servicesAndPublishedObjects.length; i++) {
				ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[i];
				if (serviceAndPublishedObjects!=null) serviceAndPublishedObjects._service.stop();
				_servicesAndPublishedObjects[i] = null;
			}
		}
	}

	@Given("^there are (\\d+) user manager services$")
	public void thereAreUserManagerServices(int numberOfServices) {
		_servicesAndPublishedObjects = new ServiceAndPublishedObjects[numberOfServices];
	}

	@When("^user manager services are started$")
    public void userManagerServicesAreStarted(List<CukeAppInfo> appInfos) throws Exception {
		for (CukeAppInfo appInfo : appInfos) {
			assertNotNull(_servicesAndPublishedObjects);
			int instance = appInfo.getInstance();
			assertTrue(instance < _servicesAndPublishedObjects.length);
			assertNull(_servicesAndPublishedObjects[instance]);

			AppInfo ai = appInfo.of();

			PrestoClient client = mock(PrestoClient.class);
			Mockito.when(client.getAppInfo()).thenReturn(ai);

			ServiceAndPublishedObjects serviceAndPublishedObjects = new ServiceAndPublishedObjects(client);
			_servicesAndPublishedObjects[instance] = serviceAndPublishedObjects;
			serviceAndPublishedObjects._service.start();

			Mockito
				.when(client.publish(Mockito.any()))
				.thenAnswer(invocation -> {
					Obj obj = (Obj) invocation.getArguments()[0];
					assertTrue(obj instanceof UserStatusObj);
					UserStatusObj us = (UserStatusObj) obj;
					serviceAndPublishedObjects._publishedObjects.add(us);
					return 0;
				});
		}
	}

	@When("^user manager services are stopped$")
	public void userManagerServicesAreStopped(List<CukeAppInfo> appInfos) {
		assertNotNull(_servicesAndPublishedObjects);
		for (CukeAppInfo appInfo : appInfos) {
			int instance = appInfo.getInstance();
			assertTrue(instance < _servicesAndPublishedObjects.length);
			assertNotNull(_servicesAndPublishedObjects[instance]);
			MadrigalUserManager service = _servicesAndPublishedObjects[instance]._service;
			service.stop();
			_servicesAndPublishedObjects[instance] = null;
		}
	}

	@When("^user manager service receives ft member notification$")
	public void userManagerServiceReceivesFtMemberNotifications(List<CukeFtMember> ftMembers) {
		assertNotNull(_servicesAndPublishedObjects);
		for (CukeFtMember ftMember : ftMembers) {
			FtMemberObj obj = ftMember.of();
			int instance = obj.getInstance();
			assertTrue(instance < _servicesAndPublishedObjects.length);
			ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[instance];
			assertNotNull(serviceAndPublishedObjects);
			serviceAndPublishedObjects._service.onFtMemberMessage(obj);
		}
	}

	@When("^user manager service receives credentials$")
	public void userManagerServiceReceivesCredentials(List<CukeCredentials> credentials) {
		assertNotNull(_servicesAndPublishedObjects);
		for (CukeCredentials cred : credentials) {
			CredentialsObj obj = cred.of();
			int instance = cred.getInstance();
			if (instance < 0) {
				for (int i=0; i<_servicesAndPublishedObjects.length; i++) {
					ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[i];
					if (serviceAndPublishedObjects != null) serviceAndPublishedObjects._service.onCredentialsMessage(obj);
				}
			} else {
				assertTrue(instance < _servicesAndPublishedObjects.length);
				ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[instance];
				assertNotNull(serviceAndPublishedObjects);
				serviceAndPublishedObjects._service.onCredentialsMessage(obj);
			}
		}
	}

	@When("^user manager service receives a user request$")
	public void userManagerServiceReceivesAUserRequest(List<CukeUserRequest> requests) {
		assertNotNull(_servicesAndPublishedObjects);
		for (CukeUserRequest request : requests) {
			UserStatusObj obj = request.of();
			for (int i=0; i<_servicesAndPublishedObjects.length; i++) {
				ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[i];
				if (serviceAndPublishedObjects != null) serviceAndPublishedObjects._service.onUserRequestMessage(obj, true);
			}
		}
	}

	// when it comes up each user manager service performs a snapSubscribe for user status
	@Then("^user manager service instance (\\d+) receives user status$")
	public void userManagerServiceInstanceReceivesUserStatus(int instance, List<CukeUserStatus> statuses) {
		assertNotNull(_servicesAndPublishedObjects);
		assertTrue(instance < _servicesAndPublishedObjects.length);
		ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[instance];
		assertNotNull(serviceAndPublishedObjects);

		for (CukeUserStatus status : statuses) {
			UserStatusObj obj = status.of();
			serviceAndPublishedObjects._service.onUserResponseMessage(obj);
		}
	}

	@Then("^user manager service instance (\\d+) publishes user status$")
	public void userManagerServiceInstancePublishesUserStatus(int instance, List<CukeUserStatus> statuses) {
		assertNotNull(_servicesAndPublishedObjects);
		assertTrue(instance < _servicesAndPublishedObjects.length);
		ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[instance];
		assertNotNull(serviceAndPublishedObjects);

		List<Obj> publishedObjects = serviceAndPublishedObjects._publishedObjects;
		assertEquals(statuses.size(), publishedObjects.size(), "published list size for instance "+instance);
		for (int i=0; i<statuses.size(); i++) {
			Obj obj = publishedObjects.get(i);
			assertTrue(obj instanceof UserStatusObj);
			UserStatusObj actualObj = (UserStatusObj) obj;
			UserStatusObj expectedObj = statuses.get(i).of();
			assertEquals(toStr(expectedObj), toStr(actualObj));
		}
		publishedObjects.clear();

		for (CukeUserStatus status : statuses) {
			UserStatusObj obj = status.of();
			for (int i=0; i<_servicesAndPublishedObjects.length; i++) {
				serviceAndPublishedObjects = _servicesAndPublishedObjects[i];
				if (serviceAndPublishedObjects != null) serviceAndPublishedObjects._service.onUserResponseMessage(obj);
			}
		}
	}

	@Then("^user manager service instance (\\d+) publishes no user status$")
	public void userManagerServiceInstancePublishesNoUserStatus(int instance) {
		assertNotNull(_servicesAndPublishedObjects);
		assertTrue(instance < _servicesAndPublishedObjects.length);
		ServiceAndPublishedObjects serviceAndPublishedObjects = _servicesAndPublishedObjects[instance];
		assertNotNull(serviceAndPublishedObjects);

		List<Obj> publishedObjects = serviceAndPublishedObjects._publishedObjects;
		assertEquals(0, publishedObjects.size(), "published list size for instance "+instance);
	}
}
