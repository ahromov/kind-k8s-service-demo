package com.example.demo5.service.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import java.io.Serializable;
import java.time.Instant;
import lombok.Builder;
import lombok.Value;

/** DTO for {@link com.example.demo5.entity.DemoEntity} */
@Value
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
@Schema(name = "DemoDto", description = "DTO для передачі даних сутності DemoEntity через API")
public class DemoDto implements Serializable {

  @Schema(
      description = "Унікальний ідентифікатор запису",
      example = "1",
      accessMode = Schema.AccessMode.READ_ONLY)
  Long id;

  @Schema(
      description = "Зовнішній ідентифікатор сутності",
      example = "EXT-12345",
      requiredMode = Schema.RequiredMode.REQUIRED)
  String externalId;

  @Schema(
      description = "Поточний статус сутності",
      example = "ACTIVE",
      requiredMode = Schema.RequiredMode.REQUIRED)
  String status;

  @Schema(
      description = "Дата та час створення запису у форматі ISO-8601 (UTC)",
      example = "2026-01-09T14:45:46Z",
      accessMode = Schema.AccessMode.READ_ONLY,
      type = "string",
      format = "date-time")
  Instant createdAt;
}
