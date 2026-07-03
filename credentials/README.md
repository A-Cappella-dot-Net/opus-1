# credentials

A simple credentials application: `FileCredentialsPublisher` reads users and their venue credentials from a CSV file and publishes them onto presto subjects, where the rest of the system (user managers, line handlers) picks them up. It is deliberately simple — a production deployment would want something considerably more robust in its place. Assembled from Spring wiring and launched through `continuo.Main`.
