package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.Steps;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface StepsRepository extends JpaRepository<Steps, Long> {
    
    @Query("SELECT COALESCE(SUM(s.stepCount), 0), " +
           "COALESCE(SUM(s.distanceM), 0.0), " +
           "COALESCE(SUM(s.caloriesBurned), 0.0) " +
           "FROM Steps s WHERE s.userId = :userId AND s.recordedDate = :date")
    Object[] findDailyTotals(@Param("userId") Long userId, @Param("date") LocalDate date);
    
    List<Steps> findByUserIdAndRecordedDateOrderByRecordedAtDesc(Long userId, LocalDate recordedDate);
}