using System.ServiceProcess;

namespace Watchdog.GUI.Services
{
    public class ServiceControl
    {
        private readonly string _serviceName;

        public ServiceControl(string name)
        {
            _serviceName = name;
        }

        public void Start()
        {
            using var sc = new ServiceController(_serviceName);
            if (sc.Status != ServiceControllerStatus.Running)
                sc.Start();
        }

        public void Stop()
        {
            using var sc = new ServiceController(_serviceName);
            if (sc.Status != ServiceControllerStatus.Stopped)
                sc.Stop();
        }
    }
}
