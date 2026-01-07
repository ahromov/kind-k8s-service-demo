package com.example.demo5.config;

import com.fasterxml.jackson.core.JsonStreamContext;
import java.beans.ConstructorProperties;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.regex.Pattern;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import net.logstash.logback.mask.ValueMasker;

@Slf4j
public class RegexValueMasker implements ValueMasker {
  private static final String MESSAGE_FIELD_NAME = "body";

  private static final int MAX_MASKED_LENGTH = 5000;

  private static final AtomicBoolean WARN_LOGGED = new AtomicBoolean(false);

  private final List<PatternData> patternsData = new ArrayList<>();

  @SneakyThrows
  public RegexValueMasker() {
    try (InputStream inputStream =
        this.getClass().getClassLoader().getResourceAsStream("log-mask.patterns")) {
      if (inputStream != null) {
        try (BufferedReader reader =
            new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
          String line;
          while ((line = reader.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty() || line.startsWith("#")) {
              continue;
            }
            String[] split = line.split("~", 2);
            if (split.length == 2) {
              patternsData.add(new PatternData(Pattern.compile(split[1]), split[0]));
            } else {
              patternsData.add(new PatternData(Pattern.compile(line), "***"));
            }
          }
        }
      } else {
        log.warn("RegexValueMasker: file log-mask.patterns not found in classpath");
      }
    }
  }

  @Override
  public Object mask(JsonStreamContext context, Object o) {
    if (context != null
        && MESSAGE_FIELD_NAME.equals(context.getCurrentName())
        && o instanceof CharSequence) {

      String result = o.toString();

      for (PatternData patternData : patternsData) {
        try {
          result = patternData.getPattern().matcher(result).replaceAll(patternData.getMask());
        } catch (Exception e) {
          log.debug("RegexValueMasker: regex error {}, masking skipped", patternData.getPattern());
        }
      }

      if (result.length() > MAX_MASKED_LENGTH) {
        result = result.substring(0, MAX_MASKED_LENGTH) + "...[masked truncated]";

        if (WARN_LOGGED.compareAndSet(false, true)) {
          log.warn(
              "RegexValueMasker: masked message symbol limit in {} symbols has been exceeded.",
              MAX_MASKED_LENGTH);
        }
      }

      return result;
    }
    return o;
  }

  @EqualsAndHashCode
  @Getter
  static final class PatternData {
    private final Pattern pattern;
    private final String mask;

    @ConstructorProperties({"pattern", "mask"})
    public PatternData(final Pattern pattern, final String mask) {
      this.pattern = pattern;
      this.mask = mask;
    }
  }
}
