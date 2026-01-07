package com.example.demo5.service.impl;

import com.example.demo5.repository.DemoRepository;
import com.example.demo5.service.DemoService;
import com.example.demo5.service.dto.DemoDto;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DemoServiceImpl implements DemoService {

  private final DemoRepository demoRepository;

  @Override
  public List<DemoDto> getAll() {
    return demoRepository.findAll().stream()
        .map(
            e ->
                DemoDto.builder()
                    .id(e.getId())
                    .externalId(e.getExternalId())
                    .status(e.getStatus())
                    .createdAt(e.getCreatedAt())
                    .build())
        .toList();
  }
}
