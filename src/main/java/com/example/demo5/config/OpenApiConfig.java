package com.example.demo5.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class OpenApiConfig {

  private final ServiceProperties props;

  @Bean
  public OpenAPI baseOpenAPI() {
    var info =
        new Info()
            .title(props.getOpenApi().getTitle())
            .version(props.getOpenApi().getVersion())
            .description(props.getOpenApi().getDescription());

    var openapi =
        new OpenAPI()
            .info(info)
            .addServersItem(
                new Server()
                    .url(props.getOpenApi().getServerUrl())
                    .description("Primary API server"));

    if (Boolean.TRUE.equals(props.getOpenApi().getUseBearerToken())) {
      var bearerScheme =
          new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT");

      openapi
          .schemaRequirement("BearerAuth", bearerScheme)
          .addSecurityItem(new SecurityRequirement().addList("BearerAuth"));
    }

    return openapi;
  }
}
