package com.example.demo5.controller.docs;

import com.example.demo5.service.dto.DemoDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;

@Operation(
    summary = "Get all demo entities",
    description = "Returns a list of all demo entities available in the system")
@ApiResponse(
    responseCode = "200",
    description = "Successful retrieval of demo entities",
    content =
        @Content(
            mediaType = "application/json",
            array = @ArraySchema(schema = @Schema(implementation = DemoDto.class))))
@ApiResponse(responseCode = "500", description = "Internal server error")
public @interface GetAllDemosAPI {}
