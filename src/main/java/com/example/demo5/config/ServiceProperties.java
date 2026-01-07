package com.example.demo5.config;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Setter
@Getter
@RequiredArgsConstructor
@ConfigurationProperties(prefix = "service")
public class ServiceProperties {

  private OpenApiProperties openApi;
  private CorsProperties cors;

  @Getter
  @Setter
  public static class OpenApiProperties {
    private String title;
    private String version;
    private String description;
    private Boolean useBearerToken;
    private String serverUrl;
  }

  @Getter
  @Setter
  public static class CorsProperties {
    private Boolean enabled;
  }
}
