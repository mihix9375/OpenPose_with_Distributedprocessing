using System.Text.Json.Serialization;

namespace OpenPoseServer
{
    public class WorkerRegistrationRequest
    {
        public string? Url { get; set; }
    }

    public class JobRequest
    {
        public string? VideoPathLeft { get; set; }
        public string? VideoPathRight { get; set; }
        public string? SerialNumberRight { get; set; }
        public string? SerialNumberLeft { get; set; }
        public string? Mode { get; set; }
    }

    // JSONのシリアライズ設定もここに
    [JsonSerializable(typeof(WorkerRegistrationRequest))]
    [JsonSerializable(typeof(JobRequest))]
    public partial class AppJsonSerializerContext : JsonSerializerContext
    {
    }
}
