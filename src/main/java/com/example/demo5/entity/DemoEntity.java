package com.example.demo5.entity;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "demo_entity")
public class DemoEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "demo_entity_id_seq")
  @SequenceGenerator(
      name = "demo_entity_id_seq",
      sequenceName = "demo_entity_id_seq",
      allocationSize = 1)
  @Column(name = "id", nullable = false)
  private Long id;

  @Column(name = "external_id", nullable = false, length = 64)
  private String externalId;

  @Column(name = "status", nullable = false, length = 32)
  private String status;

  @ColumnDefault("now()")
  @Column(name = "created_at", nullable = false)
  private Instant createdAt;
}
