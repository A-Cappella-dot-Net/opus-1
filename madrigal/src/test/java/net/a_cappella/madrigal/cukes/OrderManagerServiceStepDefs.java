package net.a_cappella.madrigal.cukes;

import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.madrigal.ICredentialsCache;
import net.a_cappella.madrigal.IInstrumentCache;
import net.a_cappella.madrigal.ILoginManagerAdaptor;
import net.a_cappella.madrigal.common.constants.MadrigalActionOnFailover;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;
import net.a_cappella.madrigal.common.obj.OrderCoder;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.cukes.adaptors.*;
import net.a_cappella.madrigal.om.OrderManagerService;
import net.a_cappella.madrigal.om.OrderManagerServiceParams;
import net.a_cappella.madrigal.om.logic.DelRetryType;
import net.a_cappella.madrigal.user.EcnUserManager;
import net.a_cappella.presto.ps.SnSManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;

public class OrderManagerServiceStepDefs {
    private static final Logger log = LoggerFactory.getLogger(OrderManagerServiceStepDefs.class);

    private final Map<String, OrderObj> _orderCache = new HashMap<>();

	private OrderManagerService _oms;

	private SnSManager _sns;
	private CukeLhClient _lhClient;
	private final String _ecn = "ecn";
	private final ICredentialsCache _credentialsCache = new CukeCredentialsCache();
	private final IInstrumentCache _instrumentCache = new CukeInstrumentCache();
	private final CukeOrderManagerAdaptor _ecnAdaptor = new CukeOrderManagerAdaptor();
	private final OrderManagerServiceParams _omsParams0 = new OrderManagerServiceParams(_ecnAdaptor, DelRetryType.DISABLED, 0); // reference set
	private final OrderManagerServiceParams _omsParams = new OrderManagerServiceParams(_ecnAdaptor, DelRetryType.DISABLED, 0); // working set
	private EcnUserManager _ecnUserManager;
	private final ILoginManagerAdaptor _loginMgrAdaptor = mock(ILoginManagerAdaptor.class);

	private final EcnCredentialsObj uidCreds = new EcnCredentialsObj();
	{
		uidCreds.set("uid", "ecn", "ecnUid", "ecnPwd", 0);
	}

    static {
        try {
			ObjectManager.getInstance().setMsgInstantiators(
                Arrays.asList(
                    new MsgInstantiator(OrderObj.class.getName(), OrderCoder.class.getName(), null)
                )
            );
        } catch (Exception e) {
            log.error("", e);
        }
    }

	@Before
	public void before() {
		_sns = mock(SnSManager.class);
		_lhClient = new CukeLhClient(_sns, new AppInfo(""));
		_ecnAdaptor.connectToExchange();
		_ecnUserManager = new EcnUserManager(_lhClient, _ecn, _loginMgrAdaptor);
	}

	@Given("^an OrderManagerService is configured with$")
	public void anOrderManagerServiceIsConfiguredWith(List<OrderManagerServiceConfig> configs) {
		DelRetryType delRetryType = _omsParams0.getDelRetryType();
		int delRetryConstant = _omsParams0.getDelRetryConstant();
		boolean nativeIocSupported = _omsParams0.isNativeIocSupported();
		boolean conflateRequests = _omsParams0.isConflateRequests();
		boolean processOnePendingRequestAtATime = _omsParams0.isProcessOnePendingRequestAtATime();
		boolean useDelAddForPriceChange = _omsParams0.isUseDelAddForPriceChange();
		boolean strictRwt = _omsParams0.isStrictRwt();
		MadrigalActionOnFailover actionOnFailover = _omsParams0.getActionOnFailover();

		if (configs.isEmpty()) configs = Arrays.asList(new OrderManagerServiceConfig());
		for (OrderManagerServiceConfig config : configs) {
			delRetryType = config.getDelRetryType(delRetryType);
			delRetryConstant = config.getDelRetryConstant(delRetryConstant);
			nativeIocSupported = config.isNativeIocSupported(nativeIocSupported);
			conflateRequests = config.isConflateRequests(conflateRequests);
			processOnePendingRequestAtATime = config.isProcessOnePendingRequestAtATime(processOnePendingRequestAtATime);
			useDelAddForPriceChange = config.isUseDelAddForPriceChange(useDelAddForPriceChange);
			strictRwt = config.isStrictRwt(strictRwt);
			actionOnFailover = config.getActionOnFailover(actionOnFailover);
		}

		_omsParams0.set(delRetryType, delRetryConstant, nativeIocSupported, conflateRequests, processOnePendingRequestAtATime, useDelAddForPriceChange, strictRwt, actionOnFailover);
		_omsParams.set(delRetryType, delRetryConstant, nativeIocSupported, conflateRequests, processOnePendingRequestAtATime, useDelAddForPriceChange, strictRwt, actionOnFailover);

		_oms = new OrderManagerService(_lhClient, _ecn, _credentialsCache, _instrumentCache, _omsParams, _ecnAdaptor, _ecnUserManager);
		_oms.start();
		log.info(_omsParams.toString());
	}

	@Given("^the OrderManagerService is further configured with$")
	public void theOrderManagerServiceIsFurtherConfiguredWith(List<OrderManagerServiceConfig> configs) {
		DelRetryType delRetryType = _omsParams0.getDelRetryType();
		int delRetryConstant = _omsParams0.getDelRetryConstant();
		boolean nativeIocSupported = _omsParams0.isNativeIocSupported();
		boolean conflateRequests = _omsParams0.isConflateRequests();
		boolean processOnePendingRequestAtATime = _omsParams0.isProcessOnePendingRequestAtATime();
		boolean useDelAddForPriceChange = _omsParams0.isUseDelAddForPriceChange();
		boolean strictRwt = _omsParams0.isStrictRwt();
		MadrigalActionOnFailover actionOnFailover = _omsParams0.getActionOnFailover();

		if (configs.isEmpty()) configs = Arrays.asList(new OrderManagerServiceConfig());
		for (OrderManagerServiceConfig config : configs) {
			delRetryType = config.getDelRetryType(delRetryType);
			delRetryConstant = config.getDelRetryConstant(delRetryConstant);
			nativeIocSupported = config.isNativeIocSupported(nativeIocSupported);
			conflateRequests = config.isConflateRequests(conflateRequests);
			processOnePendingRequestAtATime = config.isProcessOnePendingRequestAtATime(processOnePendingRequestAtATime);
			useDelAddForPriceChange = config.isUseDelAddForPriceChange(useDelAddForPriceChange);
			strictRwt = config.isStrictRwt(strictRwt);
			actionOnFailover = config.getActionOnFailover(actionOnFailover);
		}

		_omsParams.set(delRetryType, delRetryConstant, nativeIocSupported, conflateRequests, processOnePendingRequestAtATime, useDelAddForPriceChange, strictRwt, actionOnFailover);

		_omsParams.init();
		log.info(_omsParams.toString());
	}

    @When("^a parent order is received from client$")
	public void aParentOrderIsReceivedFromClient(List<CukeOrder> cukeOrders) {
		for (CukeOrder cukeOrder : cukeOrders) {
			OrderObj order = cukeOrder.defaults().adaptRequest(_orderCache, _credentialsCache, _instrumentCache);
			_oms.onOrderRequest(order);
		}
	}

	@Then("^one or more children orders are sent to exchange$")
	public void oneOrMOreChildrenOrdersAreSentToExchange(List<CukeEcnOrder> orders) {
		_ecnAdaptor.verifyOrdersCount(orders.size());
		for (CukeEcnOrder order : orders) {
			_ecnAdaptor.verifyOrder(order.defaults());
		}
	}

	@Then("^no child order is sent to exchange$")
	public void noChildOrderIsSentToExchange() {
		_ecnAdaptor.verifyNoOrders();
	}

	@When("^an execution report is received from exchange for child order$")
	public void anExecutionReportIsReceivedFromExchangeForChildOrder(List<CukeOrder> cukeErs) {
		for (CukeOrder cukeEr : cukeErs) {
			_oms.onOrderResponse(cukeEr.adaptResponse());
		}
	}

	@Then("^one or more execution reports are sent to client for parent order$")
	public void oneOrMoreExecutionReportsAreSentToClientForParentOrder(List<CukeOrder> cukeErs) {
		_lhClient.verifyExecutionReportsCount(cukeErs.size());
		for (CukeOrder cukeEr : cukeErs) {
			_lhClient.verifyExecutionReport(cukeEr.defaults(MadrigalMode.RESPONSE));
		}
	}

	@Then("^no execution report is sent to client$")
	public void noExecutionReportIsSentToClient() {
		_lhClient.verifyNoExecutionReports();
	}

	@When("^a market data snapshot is received from exchange$")
	public void aMarketDataSnapshotIsReceivedFromExchange(List<CukeEcnPrice> cukePrices) {
		for (CukeEcnPrice cukePrice : cukePrices) {
			_oms.onEcnPrice(cukePrice.adapt());
		}
	}

	@Given("^the OrderManagerService is activated with execId (\\d+)$")
	public void theOrderManagerServiceIsActivatedWithExecId(long execId) {
		_oms.setExecId(execId);
	}

	@When("^requests are received from cache or clients$")
	public void requestsAreReceivedFromCacheOrClients(List<CukeOrder> cukeRequests) {
		for (CukeOrder cukeRequest : cukeRequests) {
			OrderObj request = cukeRequest.defaults().adaptRequest(_orderCache, _credentialsCache, _instrumentCache);
			if (MadrigalReqType.ADD == request.getReqType()) {
				OrderObj state = cukeRequest.defaults().adaptState(_credentialsCache, _instrumentCache);
				// 'artificial' ADD state when an ADD request is not yet ACKed
				_oms.getInactiveStates().onSubscriptionMessage(state, true);
			}
			_oms.getInactiveStates().onSubscriptionMessage(request, true);
		}
	}

	@When("^states are received from cache$")
	public void statesAreReceivedFromCache(List<CukeOrder> cukeResponses) {
		for (CukeOrder cukeResponse : cukeResponses) {
			OrderObj state = cukeResponse.defaults().adaptState(_credentialsCache, _instrumentCache);
			// if the intent is to create the 'artificial' ADD state when an ADD request is not yet ACKed then don't;
			// that state is created when 'requests are received from cache or clients'
			assertTrue(state.getStatus()!=null && state.getStatus()!= MadrigalOrdStatus.NULL_VAL, "Status Not supposed to be NULL");
			_oms.getInactiveStates().onSubscriptionMessage(state, true);
		}
	}

	@When("^unprocessed fills are received from exchange$")
	public void unprocessedFillsAreReceivedFromExchange(List<CukeOrder> cukeResponses) {
		for (CukeOrder cukeResponse : cukeResponses) {
			OrderObj fill = cukeResponse.ecnDefaults().adaptUnprocessedFill();
			_oms.getInactiveStates().onSubscriptionMessage(fill, true);
		}
	}

	@When("^trader logging into exchange triggers activation of all trader orders$")
	public void traderLoggingIntoExchangeTriggersActivationOfAllTraderOrders() {
		_oms.activateOrders("ecnUid");
	}

}
