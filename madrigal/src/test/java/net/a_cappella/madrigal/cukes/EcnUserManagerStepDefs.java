/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.madrigal.cukes;

import io.cucumber.java.After;
import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import net.a_cappella.cembalo.constants.UserStatus;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.ILoginManagerAdaptor;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.madrigal.cukes.adaptors.CukeEcnCredentials;
import net.a_cappella.madrigal.cukes.adaptors.um.*;
import net.a_cappella.madrigal.user.EcnUserManager;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

public class EcnUserManagerStepDefs {
    private static final Logger log = LoggerFactory.getLogger(EcnUserManagerStepDefs.class);

	private ManagerAndPublishedObjects[] _managersAndPublishedObjects;
	private String _ecn;

	private static class ManagerAndPublishedObjects {
		private final EcnUserManager _manager;
		private final List<Obj> _publishedRequests = new ArrayList<>();
		private final List<Obj> _publishedResponses = new ArrayList<>();
		private final List<CukeExchangeLogOp> _exchangeCommands = new ArrayList<>();
		
		public ManagerAndPublishedObjects(PrestoClient client, String ecn, ILoginManagerAdaptor adaptor) {
			_manager = new EcnUserManager(client, ecn, adaptor);
			_manager.setLoopbackDelayMillis("0");
		}
	}

	@Before
	public void before() {
	}
	@After
	public void after() {
		if (_managersAndPublishedObjects!=null) {
			for (int i=0; i<_managersAndPublishedObjects.length; i++) {
				ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[i];
				if (managerAndPublishedObjects!=null) managerAndPublishedObjects._manager.stop();
				_managersAndPublishedObjects[i] = null;
			}
		}
	}

	@Given("^there are (\\d+) ecn user managers for ecn (.+)$")
	public void thereAreEcnUserManagers(int numberOfManagers, String ecn) {
		_ecn = ecn;
		_managersAndPublishedObjects = new ManagerAndPublishedObjects[numberOfManagers];
	}

	@When("^ecn user managers are started$")
	public void ecnUserManagersAreStarted(List<CukeAppInfo> appInfos) throws Exception {
		for (CukeAppInfo appInfo : appInfos) {
			assertNotNull(_managersAndPublishedObjects);
			int instance = appInfo.getInstance();
			assertTrue(instance < _managersAndPublishedObjects.length);
			assertNull(_managersAndPublishedObjects[instance]);

			AppInfo ai = appInfo.of();

			PrestoClient client = mock(PrestoClient.class);
			Mockito.when(client.getAppInfo()).thenReturn(ai);

			ILoginManagerAdaptor ecnAdaptor = mock(ILoginManagerAdaptor.class);

			ManagerAndPublishedObjects managerAndPublishedObjects = new ManagerAndPublishedObjects(client, _ecn, ecnAdaptor);
			_managersAndPublishedObjects[instance] = managerAndPublishedObjects;
			managerAndPublishedObjects._manager.start();

			Mockito
				.when(client.publish(Mockito.any()))
				.thenAnswer(invocation -> {
					Obj obj = (Obj) invocation.getArguments()[0];
					assertTrue(obj instanceof EcnUserStatusObj);
					EcnUserStatusObj eus = (EcnUserStatusObj) obj;
					if (eus.getMadrigalMode() == MadrigalMode.REQUEST) {
						managerAndPublishedObjects._publishedRequests.add(eus);
					} else {
						managerAndPublishedObjects._publishedResponses.add(eus);
					}
					return 0;
				});
			Mockito
				.doAnswer(invocation -> {
					String uid = invocation.getArgument(0);
					String pwd = invocation.getArgument(1);
					managerAndPublishedObjects._exchangeCommands.add(new CukeExchangeLogOp("login", uid, pwd));
					return null;
				})
				.when(ecnAdaptor).login(Mockito.anyString(), Mockito.anyString());
			Mockito
				.doAnswer(invocation -> {
					String uid = invocation.getArgument(0);
					String pwd = invocation.getArgument(1);
					managerAndPublishedObjects._exchangeCommands.add(new CukeExchangeLogOp("logout", uid, pwd));
					return null;
				})
				.when(ecnAdaptor).logout(Mockito.anyString(), Mockito.anyString());
		}
	}

	@When("^ecn user managers are stopped$")
	public void ecnUserManagersAreStopped(List<CukeAppInfo> appInfos) {
		assertNotNull(_managersAndPublishedObjects);
		for (CukeAppInfo appInfo : appInfos) {
			int instance = appInfo.getInstance();
			assertTrue(instance < _managersAndPublishedObjects.length);
			assertNotNull(_managersAndPublishedObjects[instance]);
			EcnUserManager manager = _managersAndPublishedObjects[instance]._manager;
			manager.stop();
			_managersAndPublishedObjects[instance] = null;
		}
	}

	// when it comes up each ecn user manager performs a snapSubscribe for ecn user status
	@Then("^ecn user manager instance (\\d+) receives ecn user status$")
	public void ecnUserManagerInstanceReceivesEcnUserStatus(int instance, List<CukeEcnUserStatus> statuses) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		for (CukeEcnUserStatus status : statuses) {
			status.setMode(MadrigalMode.RESPONSE);
			EcnUserStatusObj obj = status.of();
			managerAndPublishedObjects._manager.onEcnUserStatusMessage(obj);
		}
	}

	@When("^ecn user manager receives ft member notification$")
	public void ecnUserManagerReceivesFtMemberNotifications(List<CukeFtMember> ftMembers) {
		assertNotNull(_managersAndPublishedObjects);
		for (CukeFtMember ftMember : ftMembers) {
			FtMemberObj obj = ftMember.of();
			int instance = obj.getInstance();
			assertTrue(instance < _managersAndPublishedObjects.length);
			ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
			assertNotNull(managerAndPublishedObjects);
			managerAndPublishedObjects._manager.onFtMemberMessage(obj);
		}
	}

	@When("^ecn user manager receives ecn credentials$")
	public void ecnUserManagerReceivesEcnCredentials(List<CukeEcnCredentials> credentials) {
		assertNotNull(_managersAndPublishedObjects);
		for (CukeEcnCredentials cred : credentials) {
			EcnCredentialsObj obj = cred.of();
			for (int i=0; i<_managersAndPublishedObjects.length; i++) {
				ManagerAndPublishedObjects serviceAndPublishedObjects = _managersAndPublishedObjects[i];
				if (serviceAndPublishedObjects != null) serviceAndPublishedObjects._manager.onEcnCredentialsMessage(obj);
			}
		}
	}

	@When("^ecn user manager instance (\\d+) receives ecn credentials$")
	public void ecnUserManagerInstanceReceivesEcnCredentials(int instance, List<CukeEcnCredentials> credentials) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		for (CukeEcnCredentials cred : credentials) {
			EcnCredentialsObj obj = cred.of();
			managerAndPublishedObjects._manager.onEcnCredentialsMessage(obj);
		}
	}

	@When("^ecn user manager receives market status$")
	public void ecnUserManagerReceivesMarketStatus(List<CukeMarketStatus> marketStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		for (CukeMarketStatus marketStatus : marketStatusList) {
			MarketStatusObj obj = marketStatus.of();
			for (int i=0; i<_managersAndPublishedObjects.length; i++) {
				ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[i];
				if (managerAndPublishedObjects != null) managerAndPublishedObjects._manager.onMarketStatusMessage(obj);
			}
		}
	}

	@When("^ecn user manager instance (\\d+) receives market status$")
	public void ecnUserManagerInstanceReceivesMarketStatus(int instance, List<CukeMarketStatus> marketStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		for (CukeMarketStatus marketStatus : marketStatusList) {
			MarketStatusObj obj = marketStatus.of();
			managerAndPublishedObjects._manager.onMarketStatusMessage(obj);
		}
	}

	@When("^ecn user manager receives user status$") // from user manager service
	public void ecnUserManagerReceivesUserStatus(List<CukeUserStatus> userStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		for (CukeUserStatus userStatus : userStatusList) {
			UserStatusObj obj = userStatus.of();
			for (int i=0; i<_managersAndPublishedObjects.length; i++) {
				ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[i];
				if (managerAndPublishedObjects != null) managerAndPublishedObjects._manager.onUserStatusMessage(obj);
			}
		}
	}

	@When("^ecn user manager instance (\\d+) receives user status$") // from the managed cache as a result of a snapSubscribe
	public void ecnUserManagerInstanceReceivesUserStatus(int instance, List<CukeUserStatus> userStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		for (CukeUserStatus userStatus : userStatusList) {
			UserStatusObj obj = userStatus.of();
			managerAndPublishedObjects._manager.onUserStatusMessage(obj);
		}
	}

	@When("^ecn user manager instance (\\d+) receives response from ecn$")
	public void ecnUserManagerInstanceReceivesResponseFromExchange(int instance, List<CukeExchangeLogOpResponse> ecnResponseList) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		for (CukeExchangeLogOpResponse ecnResponse : ecnResponseList) {
			EcnUserStatusObj ecnUserStatus = new EcnUserStatusObj();
			ecnUserStatus.setResponse(instance, null, _ecn, ecnResponse.getEcnUid(), null, MadrigalLogOp.NULL_VAL, EcnConverters.convert(UserStatus.valueOf(ecnResponse.getStatus())), ecnResponse.getText(), System.currentTimeMillis());
			ecnUserStatus.setOnLoopback(true);
			managerAndPublishedObjects._manager.onEcnUserStatusMessage(ecnUserStatus);
		}
	}

	@Then("^ecn user manager instance (\\d+) publishes ecn user request$")
	public void ecnUserManagerInstancePublishesEcnUserRequest(int instance, List<CukeEcnUserStatus> ecnUserStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<Obj> actualObjs = managerAndPublishedObjects._publishedRequests;
		assertEquals(ecnUserStatusList.size(), actualObjs.size(), "published list size for instance "+instance);

		for (int i=0; i<ecnUserStatusList.size(); i++) {
			Obj actualObj = actualObjs.get(i);
			assertTrue(actualObj instanceof EcnUserStatusObj);
			EcnUserStatusObj actualUserStatusObj = (EcnUserStatusObj) actualObj;
			CukeEcnUserStatus expectedObj = ecnUserStatusList.get(i);
			expectedObj.setInstance(instance);
			expectedObj.setMode(MadrigalMode.REQUEST);
			assertEquals(toStr(expectedObj.of()), toStr(actualUserStatusObj));
		}
		actualObjs.clear();
	}

	@Then("^ecn user manager instance (\\d+) publishes no ecn user request$")
	public void ecnUserManagerInstancePublishesNoEcnUserRequest(int instance) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<Obj> actualObjs = managerAndPublishedObjects._publishedRequests;
		assertEquals(0, actualObjs.size(), "published list size for instance "+instance);
	}

	@Then("^ecn user manager instance (\\d+) publishes ecn user status$")
	public void ecnUserManagerInstancePublishesEcnUserStatus(int instance, List<CukeEcnUserStatus> ecnUserStatusList) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<Obj> actualObjs = managerAndPublishedObjects._publishedResponses;
		if (actualObjs.size()!=ecnUserStatusList.size()) log.info("actuals "+actualObjs);
		assertEquals(ecnUserStatusList.size(), actualObjs.size(), "published list size for instance "+instance);

		for (int i=0; i<ecnUserStatusList.size(); i++) {
			Obj actualObj = actualObjs.get(i);
			assertTrue(actualObj instanceof EcnUserStatusObj);
			EcnUserStatusObj actualUserStatusObj = (EcnUserStatusObj) actualObj;
			CukeEcnUserStatus expectedObj = ecnUserStatusList.get(i);
			expectedObj.setInstance(instance);
			expectedObj.setMode(MadrigalMode.RESPONSE);
			assertEquals(toStr(expectedObj.of()), toStr(actualUserStatusObj));
		}
		actualObjs.clear();

		for (int i=0; i<ecnUserStatusList.size(); i++) {
			CukeEcnUserStatus expectedObj = ecnUserStatusList.get(i);
			expectedObj.setMode(MadrigalMode.RESPONSE);
			EcnUserStatusObj ecnUserStatus = expectedObj.of();

			for (int j=0; j<_managersAndPublishedObjects.length; j++) {
				managerAndPublishedObjects = _managersAndPublishedObjects[j];
				if (managerAndPublishedObjects != null) {
					managerAndPublishedObjects._manager.onEcnUserStatusMessage(ecnUserStatus);
				}
			}
		}
	}

	@Then("^ecn user manager instance (\\d+) publishes no ecn user status$")
	public void ecnUserManagerInstancePublishesNoEcnUserStatus(int instance) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<Obj> actualObjs = managerAndPublishedObjects._publishedResponses;
		if (actualObjs.size()!=0) log.info("actuals "+actualObjs);
		assertEquals(0, actualObjs.size(), "published list size for instance "+instance);
	}

	private String toStr(EcnUserStatusObj eus) {
		String res = eus.getInstance()+" "+eus.getUid()+" "+eus.getEcn()+" "+eus.getEcnUid()+" "+eus.getEcnPwd()+" "+eus.getOp();
		if (eus.getMadrigalMode() != MadrigalMode.REQUEST) {
			res += " "+eus.getStatus()+" "+eus.getText();
		}
		return res;
	}

	@Then("^ecn user manager instance (\\d+) sends request to ecn$")
	public void ecnUserManagerInstanceSendsRequestToEcn(int instance, List<CukeExchangeLogOp> expectedRequests) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<CukeExchangeLogOp> actualRequests = managerAndPublishedObjects._exchangeCommands;
		assertEquals(expectedRequests.size(), actualRequests.size(), "request list size for instance "+instance);
		for (int i=0; i<expectedRequests.size(); i++) {
			CukeExchangeLogOp actualObj = actualRequests.get(i);
			CukeExchangeLogOp expectedObj = expectedRequests.get(i);
			assertEquals(expectedObj.toString(), actualObj.toString());
		}
		actualRequests.clear();
	}

	@Then("^ecn user manager instance (\\d+) sends no request to ecn$")
	public void ecnUserManagerInstanceSendsNoRequestToEcn(int instance) {
		assertNotNull(_managersAndPublishedObjects);
		assertTrue(instance < _managersAndPublishedObjects.length);
		ManagerAndPublishedObjects managerAndPublishedObjects = _managersAndPublishedObjects[instance];
		assertNotNull(managerAndPublishedObjects);

		List<CukeExchangeLogOp> actualRequests = managerAndPublishedObjects._exchangeCommands;
		assertEquals(0, actualRequests.size(), "request list size for instance "+instance);
	}
}
