# Translated from Rust WASM filter with help of generative model
import asyncio
import re
import logging
from typing import AsyncIterator
from concurrent import futures

import grpc
from envoy.service.ext_proc.v3 import external_processor_pb2 as ep
from envoy.service.ext_proc.v3 import external_processor_pb2_grpc as ep_grpc
from envoy.config.core.v3 import base_pb2 as core


# plugin manager
import sys
import json
sys.path.append("/app/apex")

# First-Party
from apex.mcp.entities.models import HookType, Message, PromptResult, Role, TextContent, PromptPosthookPayload, PromptPrehookPayload
from apex.framework.manager import PluginManager
from apex.framework.models import GlobalContext
from plugins.regex_filter.search_replace import SearchReplaceConfig


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ext-proc-PM")

class ExtProcServicer1(ep_grpc.ExternalProcessorServicer):
    async def Process(self, request_iterator: AsyncIterator[ep.ProcessingRequest], context) -> AsyncIterator[ep.ProcessingResponse]:
        req_body_buf = bytearray()
        resp_body_buf = bytearray()

        async for request in request_iterator:
            logger.info(request)
            if request.HasField("request_headers"):
                # Modify request headers
                headers = request.request_headers.headers
                yield ep.ProcessingResponse(
                    request_headers=ep.HeadersResponse(
                        response=ep.CommonResponse(
                            header_mutation=ep.HeaderMutation(
                                set_headers=[
                                    core.HeaderValueOption(
                                        header=core.HeaderValue(
                                            key="x-ext-proc-header", raw_value="hello-from-ext-proc".encode('utf-8')
                                        ),
                                        append_action=core.HeaderValueOption.APPEND_IF_EXISTS_OR_ADD
                                    )
                                ]
                            )
                        )
                    )
                )
            elif request.HasField("response_headers"):
                # Modify response headers
                headers = request.response_headers.headers
                yield ep.ProcessingResponse(
                    response_headers=ep.HeadersResponse(
                        response=ep.CommonResponse(
                            header_mutation=ep.HeaderMutation(
                                set_headers=[
                                    core.HeaderValueOption(
                                        header=core.HeaderValue(
                                            key="x-ext-proc-response-header", raw_value="processed-by-ext-proc".encode('utf-8')
                                        ),
                                        append_action=core.HeaderValueOption.APPEND_IF_EXISTS_OR_ADD
                                    )
                                ]
                            )
                        )
                    )
                )

            elif request.HasField("request_body") and request.request_body.body:
                chunk = request.request_body.body
                req_body_buf.extend(chunk)

                if getattr(request.request_body, "end_of_stream", False):
                    try:
                        text = req_body_buf.decode("utf-8")
                    except UnicodeDecodeError:
                        logger.debug("Request body not UTF-8; skipping")
                    else:
                        logger.info(json.loads(text))
                        body = json.loads(text)
                        if 'method' in body and body['method'] == "tools/call":
                            prompt = PromptPrehookPayload(name="test_prompt", args = body["params"]["arguments"])
                            global_context = GlobalContext(request_id="1", server_id="2")
                            result, contexts = await manager.invoke_hook(HookType.PROMPT_PRE_FETCH, prompt, global_context=global_context)
                            print(result.modified_payload.args)
                            body["params"]["arguments"] = result.modified_payload.args
                            body_resp = ep.ProcessingResponse(
                                request_body=ep.BodyResponse(
                                    response=ep.CommonResponse(
                                        body_mutation=ep.BodyMutation(
                                            body=json.dumps(body).encode("utf-8")
                                        )
                                    )
                                )
                            )
                        else:
                            body_resp = ep.ProcessingResponse(
                                request_body=ep.BodyResponse(
                                    response=ep.CommonResponse()
                                )
                            )
                        yield body_resp

                    req_body_buf.clear()

            # ---- Response body chunks ----
            elif request.HasField("response_body") and request.response_body.body:
                chunk = request.response_body.body
                resp_body_buf.extend(chunk)

                if getattr(request.response_body, "end_of_stream", False):
                    try:
                        text = resp_body_buf.decode("utf-8")
                    except UnicodeDecodeError:
                        logger.debug("Response body not UTF-8; skipping")
                    else:
                        body_resp = ep.ProcessingResponse(
                            response_body=ep.BodyResponse(
                                response=ep.CommonResponse()
                            )
                        )
                        yield body_resp
                    resp_body_buf.clear()

            # Handle other message types (request_body, response_body, etc.) as needed
            else:
                logger.warn("Not processed")

async def serve(host: str = "0.0.0.0", port: int = 50052):
    await manager.initialize()
    print(manager.config)

    server = grpc.aio.server()
    #server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    ep_grpc.add_ExternalProcessorServicer_to_server(ExtProcServicer1(), server)
    listen_addr = f"{host}:{port}"
    server.add_insecure_port(listen_addr)
    logger.info("Starting ext_proc MY server on %s", listen_addr)
    await server.start()
    # wait forever
    await server.wait_for_termination()

if __name__ == "__main__":
    try:
        manager = PluginManager("./apex/resources/config/config.yaml")
        asyncio.run(serve())
        #serve()
    except KeyboardInterrupt:
        logger.info("Shutting down")

