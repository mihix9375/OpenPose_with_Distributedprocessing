using System.Collections.Concurrent;

namespace OpenPoseServer
{
    public class AvailableWorkers
    {
        public List<string>? availableWorkersURL { get; private set; } = new List<string>();

        public void ControlWorkers(string url, string mode)
        {
            switch (mode)
                {
                case "Add":
                    AddWorker(url);
                    break;
                case "Remove":
                    RemoveWorker(url); 
                    break;
            }
        }

        private void AddWorker(string url)
        {
            availableWorkersURL?.Add(url);
        }

        private void RemoveWorker(string url)
        {
            availableWorkersURL?.Remove(url);
        }
    }
}
