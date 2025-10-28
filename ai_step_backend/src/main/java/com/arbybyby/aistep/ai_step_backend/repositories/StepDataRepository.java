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

    @Query("SELECT s FROM StepData s WHERE s.userId = :userId AND s.timestamp BETWEEN :startTime AND :endTime ORDER BY s.timestamp DESC")
    List<StepData> findByUserIdAndTimestampBetween(
        @Param("userId") Long userId, 
        @Param("startTime") Instant startTime, 
        @Param("endTime") Instant endTime
    );

    @Query("SELECT s FROM StepData s WHERE s.userId = :userId AND s.isValidStep = true AND s.timestamp BETWEEN :startTime AND :endTime ORDER BY s.timestamp DESC")
    List<StepData> findValidStepsByUserIdAndTimestampBetween(
        @Param("userId") Long userId, 
        @Param("startTime") Instant startTime, 
        @Param("endTime") Instant endTime
    );

    @Query("SELECT COUNT(s) FROM StepData s WHERE s.userId = :userId AND s.isValidStep = true AND s.timestamp BETWEEN :startTime AND :endTime")
    Integer countValidStepsByUserIdAndTimestampBetween(
        @Param("userId") Long userId, 
        @Param("startTime") Instant startTime, 
        @Param("endTime") Instant endTime
    );

    @Query(value = """
        SELECT 
            DATE(s.timestamp) as day,
            COUNT(CASE WHEN s.is_valid_step = true THEN 1 END) as totalSteps,
            AVG(CASE WHEN s.is_valid_step = true THEN s.magnitude * 0.78 / 1000.0 END) * COUNT(CASE WHEN s.is_valid_step = true THEN 1 END) as totalDistanceM,
            COUNT(CASE WHEN s.is_valid_step = true THEN 1 END) * 0.04 as totalCalories,
            MAX(s.timestamp) as lastEntryAt
        FROM step_data s 
        WHERE s.user_id = :userId 
            AND s.timestamp >= :startTime 
            AND s.timestamp <= :endTime
        GROUP BY DATE(s.timestamp)
        ORDER BY DATE(s.timestamp) DESC
    """, nativeQuery = true)
    List<Object[]> getDailyStepTotalsByUserId(
        @Param("userId") Long userId, 
        @Param("startTime") Instant startTime, 
        @Param("endTime") Instant endTime
    );

    @Query("SELECT s FROM StepData s WHERE s.userId = :userId ORDER BY s.timestamp DESC")
    List<StepData> findLatestByUserId(@Param("userId") Long userId);

    @Query("SELECT s FROM StepData s WHERE s.userId = :userId AND s.timestamp >= :since ORDER BY s.timestamp DESC")
    List<StepData> findRecentByUserIdSince(@Param("userId") Long userId, @Param("since") Instant since);
}