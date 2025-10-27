package main

import (
	//"context"
	"log"
	"log/slog"
	"net"

	//ext_proc "github.com/envoyproxy/go-control-plane/envoy/extensions/filters/http/ext_proc/v3"
	ext_proc "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
	ext_proc_pb "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
        "google.golang.org/protobuf/types/known/wrapperspb"
	"google.golang.org/grpc"
	//"google.golang.org/grpc/codes"
	//"google.golang.org/grpc/status"
)

// extProcServer implements the ext_proc_pb.ExternalProcessingServiceServer interface
type extProcServer struct {
//	ext_proc_pb.UnimplementedExternalProcessingServiceServer
}

// Process handles the gRPC stream for external processing
func (s *extProcServer) Process(stream ext_proc_pb.ExternalProcessor_ProcessServer) error {
	for {
		slog.Info("In Proces")
		req, err := stream.Recv()
		if err != nil {
			return err
		}

		resp := &ext_proc_pb.ProcessingResponse{}

		switch req.Request.(type) {
		case *ext_proc_pb.ProcessingRequest_RequestHeaders:
			headers := req.GetRequestHeaders().GetHeaders()
			log.Printf("Received request headers: %v", headers)
			slog.Info("Received request headers: %v", headers)
			// Example: Add a custom header to the request
			resp.Response = &ext_proc_pb.ProcessingResponse_RequestHeaders{
				RequestHeaders: &ext_proc_pb.HeadersResponse{
					Response: &ext_proc_pb.CommonResponse{
						HeaderMutation: &ext_proc_pb.HeaderMutation{
							SetHeaders: []*ext_proc.HeaderValueOption{
								{
									Header: &ext_proc.HeaderValue{
										Key:   "x-custom-request-header",
										Value: "processed-by-go-ext-proc",
									},
									Append: &wrapperspb.BoolValue{Value: false},
								},
							},
						},
					},
				},
			}

		case *ext_proc_pb.ProcessingRequest_ResponseHeaders:
			headers := req.GetResponseHeaders().GetHeaders()
			log.Printf("Received response headers: %v", headers)
			slog.Info("Received response headers: %v", headers)
			// Example: Add a custom header to the response
			resp.Response = &ext_proc_pb.ProcessingResponse_ResponseHeaders{
				ResponseHeaders: &ext_proc_pb.HeadersResponse{
					Response: &ext_proc_pb.CommonResponse{
						HeaderMutation: &ext_proc_pb.HeaderMutation{
							SetHeaders: []*ext_proc.HeaderValueOption{
								{
									Header: &ext_proc.HeaderValue{
										Key:   "x-custom-response-head",
										Value: "999",
									},
									Append: &wrapperspb.BoolValue{Value: false},
								},
							},
						},
					},
				},
			}

		// Add cases for RequestBody, ResponseBody, RequestTrailers, ResponseTrailers
		// based on your processing needs.

		default:
			log.Printf("Received unhandled request type: %T", req.Request)
			slog.Info("Received unhandled request type: %T", req.Request)
		}

	        log.Printf("Modify header: %v", resp)
	        slog.Info("Modify header: %v", resp)
		if err := stream.Send(resp); err != nil {
			return err
		}
	}
}

func main() {
	lis, err := net.Listen("tcp", ":50052") // Listen on a specific port
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	ext_proc_pb.RegisterExternalProcessorServer(grpcServer, &extProcServer{})

	log.Printf("Ext_proc server listening on %v", lis.Addr())
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to serve gRPC: %v", err)
	}
}
