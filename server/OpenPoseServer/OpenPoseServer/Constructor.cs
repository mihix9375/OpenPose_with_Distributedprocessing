namespace OpenPoseServer
{
    public class Constructor
    {
        public SingleProcess singleProcess          { get; }        = new();
        public MultiProcess multiProcess            { get; }        = new();
        public Log log                              { get; }        = new("");
        public AvailableWorkers availableWorkers    { get; }        = new();
    }
}
