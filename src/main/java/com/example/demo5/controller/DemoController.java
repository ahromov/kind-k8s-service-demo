package com.example.demo5.controller;

import com.example.demo5.controller.docs.GetAllDemosAPI;
import com.example.demo5.service.DemoService;
import com.example.demo5.service.dto.DemoDto;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/demo")
@RequiredArgsConstructor
@Tag(name = "Demo Controller", description = "APIs for Demo operations")
public class DemoController {

  private final DemoService demoService;

  @GetMapping
  @GetAllDemosAPI
  List<DemoDto> getAll() {
    return demoService.getAll();
  }
}
