package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.StepData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface StepDataRepository extends JpaRepository<StepData, Long> {
    
    List<StepData> findByUserIdAndTimestampBetween(Long userId, Instant startTime, Instant endTime);
    
    List<StepData> findByUserIdOrderByTimestampDesc(Long userId);
    
    @Query("SELECT sd FROM StepData sd WHERE sd.userId = :userId AND sd.isValidStep = true ORDER BY sd.timestamp DESC")
    List<StepData> findValidStepsByUserId(@Param("userId") Long userId);
    
    @Query("SELECT sd FROM StepData sd WHERE sd.userId = :userId AND sd.timestamp BETWEEN :startTime AND :endTime AND sd.isValidStep = true ORDER BY sd.timestamp DESC")
    List<StepData> findValidStepsByUserIdAndTimestampBetween(@Param("userId") Long userId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);
    
    @Query("SELECT COUNT(sd) FROM StepData sd WHERE sd.userId = :userId AND sd.timestamp BETWEEN :startTime AND :endTime AND sd.isValidStep = true")
    Integer countValidStepsByUserIdAndTimestampBetween(@Param("userId") Long userId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);
    
    @Query("SELECT CAST(sd.timestamp AS date), SUM(sd.stepCount), SUM(0.0), SUM(0), MAX(sd.timestamp) " +
           "FROM StepData sd WHERE sd.userId = :userId AND sd.timestamp BETWEEN :startTime AND :endTime AND sd.isValidStep = true " +
           "GROUP BY CAST(sd.timestamp AS date) ORDER BY CAST(sd.timestamp AS date) DESC")
    List<Object[]> getDailyStepTotalsByUserId(@Param("userId") Long userId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);
    
    void deleteByUserId(Long userId);
}
