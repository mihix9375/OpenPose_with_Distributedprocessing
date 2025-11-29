#define NOMINMAX
#include <thread>
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#include <iostream>
#include <sstream>
#include <filesystem>
#include <string>
#include <vector>
#include <cstdio>
#include <opencv2/opencv.hpp>
#include "./header/httplib.h"
#include "./header/json.hpp"
#include "./header/tinyxml2.h"
#include "openpose.grpc.pb.h"
#include <grpcpp/grpcpp.h>
#define OPENPOSE_FLAGS_DISABLE_POSE
#include <openpose/flags.hpp>
#include <openpose/headers.hpp>
#include <openpose/core/array.hpp>
#include <openpose/core/matrix.hpp>

using json = nlohmann::json;
using namespace tinyxml2;
using grpc::Server;
using grpc::ServerReaderWriter;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using OpenPoseStream::OpenPoseStreamer;
using OpenPoseStream::FrameRequest;
using OpenPoseStream::FrameResult;

/** 
 * @brief OpenPoseで画像データを処理する
 * @param opWrapper OpenPoseのラッパーインスタンス
 * @param image_data マスターから送られてきた生の画像データ (バイナリ)
 * @return 処理結果のJSON文字列
**/

std::string process_with_openpose(op::Wrapper& opWrapper, const std::string& image_data)
{
    std::vector<char> data(image_data.begin(), image_data.end());
    cv::Mat inputImage = cv::imdecode(data, cv::IMREAD_COLOR);

    if (inputImage.empty())
    {
        std::cout << "process_with_openpose() : 画像のデコードに失敗しました" << '\n';
        return {};
    }

    auto datums = std::make_shared<std::vector<std::shared_ptr<op::Datum>>>();
    datums->emplace_back(std::make_shared<op::Datum>());
    datums->at(0)->cvInputData = OP_CV2OPMAT(inputImage);

    const bool successProce = opWrapper.emplaceAndPop(datums);

    json result_json;
    result_json["version"] = 1.3;
    json peopleArray = json::array();

    if (successProce && datums != nullptr && !datums->empty())
    {
        try
        {   
            const auto& poseKeypoints = datums->at(0)->poseKeypoints;
            const auto& handLeftKeypoints = datums->at(0)->handKeypoints[0];
            const auto& handRightKeypoints = datums->at(0)->handKeypoints[1];
            
            const int numPeople = poseKeypoints.getSize(0);

            for (int p = 0; p < numPeople; ++p)
            {
                json personOBJ;
                personOBJ["person_id"] = {-1};

                json poseArray = json::array();
                const int numPoseParts = poseKeypoints.getSize(1);
                for (int part = 0; part < numPoseParts; ++part)
                {
                    poseArray.push_back(poseKeypoints[{p, part, 0}]);
                    poseArray.push_back(poseKeypoints[{p, part, 1}]);
                    poseArray.push_back(poseKeypoints[{p, part, 2}]);
                }
                personOBJ["pose_keypoints_2d"] = poseArray;

                json handLeftArray = json::array();
                const int numHandParts = handLeftKeypoints.getSize(1);
                for (int part = 0; part < numHandParts; ++part)
                {
                    handLeftArray.push_back(handLeftKeypoints[{p, part, 0}]);
                    handLeftArray.push_back(handLeftKeypoints[{p, part, 1}]);
                    handLeftArray.push_back(handLeftKeypoints[{p, part, 2}]);
                }
                personOBJ["hand_left_keypoints_2d"] = handLeftArray;

                json handRightArray = json::array();
                for (int part = 0; part < numHandParts; ++part)
                {
                    handRightArray.push_back(handRightKeypoints[{p, part, 0}]);
                    handRightArray.push_back(handRightKeypoints[{p, part, 1}]);
                    handRightArray.push_back(handRightKeypoints[{p, part, 2}]);
                }
                personOBJ["hand_right_keypoints_2d"] = handRightArray;

                personOBJ["pose_keypoints_3d"] = json::array();
                personOBJ["face_keypoints_3d"] = json::array();
                personOBJ["hand_left_keypoints_3d"] = json::array();
                personOBJ["hand_right_keypoints_3d"] = json::array();

                peopleArray.push_back(personOBJ);
            }
        }
        catch(const std::exception& e)
        {
            std::cerr << e.what() << '\n';
        }
        
    }

    result_json["people"] = peopleArray;

    return result_json.dump();
}

void match_keypoints(const op::Array<float>& points1_op, const op::Array<float>& points2_op, std::vector<cv::Point2f>& points1_cv, std::vector<cv::Point2f>& points2_cv)
{
    points1_cv.clear();
    points2_cv.clear();

    const int numPeople1 = points1_op.getSize(0);
    const int numPeople2 = points2_op.getSize(0);

    if (numPeople1 == 0 || numPeople2 == 0)
    {
        return; 
    }

    const int numKeypoints1 = points1_op.getSize(1);
    const int numKeypoints2 = points2_op.getSize(1);

    const int minKeypoints = std::min(numKeypoints1, numKeypoints2);

    points1_cv.reserve(minKeypoints);
    points2_cv.reserve(minKeypoints);

    for (int i = 0; i < minKeypoints; ++i)
    {
        float x1 = points1_op[{0, i, 0}];
        float y1 = points1_op[{0, i, 1}];
        
        float x2 = points2_op[{0, i, 0}];
        float y2 = points2_op[{0, i, 1}];
        
        points1_cv.push_back(cv::Point2f(x1, y1));
        points2_cv.push_back(cv::Point2f(x2, y2));
    }
}

std::vector<std::vector<double>> read_calibration_data(const std::string filename)
{
    tinyxml2::XMLDocument doc;  
    
    std::vector<std::vector<double>> data;

    std::string filepath = "./cam_param/" + filename + ".xml";

    if (doc.LoadFile(filepath.c_str()) == XML_SUCCESS)
    {
        XMLElement* root = doc.FirstChildElement("opencv_storage");
        if (!root)
        {
            std::cout << "read_calibration_data() : <opencv_storage> が見つかりません" << '\n';
            return {{}};
        }

        XMLElement* intrinsics = root->FirstChildElement("Intrinsics");
        if (intrinsics)
        {
            XMLElement* dataElement = intrinsics->FirstChildElement("data");
            const char* dataText = dataElement ? dataElement->GetText() : nullptr;

            if (dataText)
            {
                std::stringstream ss(dataText);
                std::vector<double> matrixData;
                double value;

                while (ss >> value)
                {
                    matrixData.push_back(value);
                }

                data.push_back(matrixData);
            }
        }

        XMLElement* distortion = root->FirstChildElement("Distortion");
        if (distortion)
        {
            XMLElement* dataElement = distortion->FirstChildElement("data");
            const char* dataText = dataElement ? dataElement->GetText() : nullptr;

            if (dataText)
            {
                std::stringstream ss(dataText);
                std::vector<double> matrixData;
                double value;

                while (ss >> value)
                {
                    matrixData.push_back(value);
                }

                data.push_back(matrixData);
            }
        }
    }

    if (data.size() != 2)
    {
        std::cout << "read_calibration_data() : キャリブレーションデータが足りません" << '\n';
        return {{}};
    }

    return data;
}


op::Array<float> process_image(op::Wrapper& opWrapper, const cv::Mat decoded_image)
{
    try
    {
        bool issuccess = false;

        auto datums = std::make_shared<std::vector<std::shared_ptr<op::Datum>>>();
        datums->emplace_back(std::make_shared<op::Datum>());
        datums->at(0)->cvInputData = OP_CV2OPMAT(decoded_image);
        issuccess = opWrapper.emplaceAndPop(datums);

        if (!(issuccess && datums != nullptr && !datums->empty()))
        {
            std::cout << "process_image() : 画像の処理に失敗" << '\n';
            return op::Array<float>({});
        }

        return datums->at(0)->poseKeypoints;
    }
    catch (const std::exception& e)
    {
        std::cerr << "process_image() : 画像の処理中に例外: " << e.what() << '\n';
    }

    return op::Array<float>{};
}

void process_with_triangulation(op::Wrapper& opWrapper, const std::string& img_right, const std::string& img_left, const std::string& serial_right, const std::string& serial_left, bool& success, json& json_data)
{
    std::vector<char> dataRight(img_right.begin(), img_right.end());
    std::vector<char> dataLeft(img_left.begin(), img_left.end());
    cv::Mat image_right_decoded = cv::imdecode(dataRight, cv::IMREAD_COLOR);
    cv::Mat image_left_decoded = cv::imdecode(dataLeft, cv::IMREAD_COLOR);

    if (image_right_decoded.empty() || image_left_decoded.empty())
    {
        std::cout << "process_with_triangulation() : 画像のデコードに失敗" << '\n';
        json_data = {};
    }

    op::Array<float> keypoints_left = process_image(opWrapper, image_left_decoded);
    op::Array<float> keypoints_right = process_image(opWrapper, image_right_decoded);

    std::vector<cv::Point2f> points1_matched, points2_matched;
    match_keypoints(keypoints_left, keypoints_right, points1_matched, points2_matched);

    if (points1_matched.empty())
    {
        json_data = nlohmann::json{ {"version", 1.3}, {"people", nlohmann::json::array()} };
    }

    std::vector<std::vector<double>> calibrationDataRight = read_calibration_data(serial_right);
    std::vector<std::vector<double>> calibrationDataLeft = read_calibration_data(serial_left);

    std::vector<float> camera_matrix_left(calibrationDataLeft[0].begin(), calibrationDataLeft[0].end());
    std::vector<float> camera_matrix_right(calibrationDataRight[0].begin(), calibrationDataRight[0].end());

    std::vector<float> dist_coeffs_left(calibrationDataLeft[1].begin(), calibrationDataLeft[1].end());
    std::vector<float> dist_coeffs_right(calibrationDataRight[1].begin(), calibrationDataRight[1].end());

    std::vector<cv::Point2f> points1_undistorted, points2_undistorted;
    cv::undistortPoints(points1_matched, points1_undistorted, camera_matrix_left, dist_coeffs_left, cv::noArray(), camera_matrix_left);
    cv::undistortPoints(points2_matched, points2_undistorted, camera_matrix_right, dist_coeffs_right, cv::noArray(), camera_matrix_right);

    cv::Mat points4D;
    cv::triangulatePoints(P1, P2, points1_undistorted, points2_undistorted, points4D);

    // 6. 正規化 (Pythonの points4D[:3] / points4D[3])
    // (cv::Mat を使ったブロードキャスト操作か、forループで正規化する)
    cv::Mat points3D;
    // ... (points4D を points3D (N x 3) に変換するロジック) ...

    // 7. 3DキーポイントをJSONに変換
    json_data = convert_3d_mat_to_json(points3D);
    success = true;
}

class OpenPoseStreamServer final : public OpenPoseStreamer::Service
{
    private:
        op::Wrapper* opWrapper_;

    public:
        OpenPoseStreamServer(op::Wrapper* wrapper) : opWrapper_(wrapper) {}

        Status ProcessStream(ServerContext* context,
                            ServerReaderWriter<FrameResult, FrameRequest>* stream)
                            override
                            {
                                FrameRequest req;

                                while (stream->Read(&req))
                                {
                                    FrameResult result;
                                    if (req.mode() == 0) // 2 camera
                                    {
                                        bool success = false;
                                        json json_data;
                                        process_with_triangulation(*opWrapper_,
                                                                req.image_right(),
                                                                req.image_left(),
                                                                req.serial_right(),
                                                                req.serial_left(),
                                                                success,
                                                                json_data);
                                        result.set_success(success);
                                        result.set_json_data(json_data.dump()); 
                                        result.set_frame_id(req.frame_id());
                                        result.set_error_message("");;

                                        stream->Write(result);
                                    }
                                }
                                return Status::OK;
                            }
};

int ProcessAndResponse(op::Wrapper& opWrapper, const std::string CurrentIP, const int CurrentPort)
{
    std::string server_addr("0.0.0.0:" + std::to_string(CurrentPort));
    OpenPoseStreamServer service(&opWrapper);

    ServerBuilder builder;

    builder.SetMaxReceiveMessageSize(100 * 1024 * 1024); 
    builder.SetMaxSendMessageSize(100 * 1024 * 1024);

    builder.AddListeningPort(server_addr, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_addr << '\n';

    server->Wait();
}

int main(int argc, char* argv[])
{
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    std::string CurrentIP;
    std::cout << "このPCのIPアドレス: ";
    std::cin >> CurrentIP;

    int CurrentPort = 44343;
    std::cout << "待機するポート(推奨 44343): " ;
    std::cin >> CurrentPort;

    std::string MASTER_IP;
    std::cout << "サーバーのIPアドレス: ";
    std::cin >> MASTER_IP;

    int MASTER_PORT;
    std::cout << "サーバーのポート: ";
    std::cin >> (int)MASTER_PORT;

    op::Wrapper opWrapper{op::ThreadManagerMode::Asynchronous};
    opWrapper.start();

    try
    {
        httplib::Client cli(MASTER_IP.c_str(), MASTER_PORT);
        cli.set_connection_timeout(5, 0);

        std::string my_url = "https://" + CurrentIP + ":" + std::to_string(CurrentPort);
        
        json json_obj;
        json_obj["url"] = my_url;
        std::string json_body = json_obj.dump();

        std::cout << "[Worker] マスター (" << MASTER_IP << ":" << MASTER_PORT <<") に登録します" << '\n';

        std::cout << "[Worker] 登録情報: " << json_body << '\n';

        auto res = cli.Post("/api/register", json_body, "application/json");

        if (res && res->status == 200)
        {
            std::cout << "[Worker] マスターへの登録成功" << '\n';
        }
        else
        {
            std::cerr << "[Worker] マスターへの登録失敗" << '\n';

            if (res)
            {
                std::cerr << "  ステータス: " << res->status << '\n';
                std::cerr << "  レスポンス: " << res->body << '\n';
            }
            else
            {
                std::cerr << "  クライアントエラー: " << res->body << '\n';
            }
            WSACleanup();
            return 1;
        }
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
    }

    if(!ProcessAndResponse(opWrapper, CurrentIP, CurrentPort))
    {
        return 1;
    }
    return 0;
}