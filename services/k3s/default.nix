{
  config,
  ...
}:

{

  services.k3s = {
    enable = true;

    nodeName = config.networking.hostName;

    # configure as a server+agent node (default at time of writing, but being explicit about it)
    role = "server";
    disableAgent = false;

    # attempt to stop pods cleanly on host shutdown, delaying host shutdown if needed
    gracefulNodeShutdown = {
      enable = true;
      shutdownGracePeriod = "1m";
      shutdownGracePeriodCriticalPods = "15s";
    };
  };

}
