Feature: Order Manager - Work in progress Scenarios
	This is normally an empty feature file used to develop new Scenarios and test 
	them before adding them to the proper feature file. This way we are running one
	scenario at a time, the one that is actively being developed.


Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt | actionOnFailover |
	| true               | true             | false                           | true                    | true      | ALWAYS_RESUME    |
  #And the OrderManagerService is activated with execId 1000

