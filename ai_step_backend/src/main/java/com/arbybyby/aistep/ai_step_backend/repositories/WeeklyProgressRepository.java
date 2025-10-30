package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.WeeklyProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface WeeklyProgressRepository extends JpaRepository<WeeklyProgress, Long> {
    
    /**
     * Find weekly progress for a specific user and week start date
     */
    Optional<WeeklyProgress> findByUserIdAndWeekStartDate(Long userId, LocalDate weekStartDate);
    
    /**
     * Get all weekly progress for a user, ordered by week start date descending
     */
    List<WeeklyProgress> findByUserIdOrderByWeekStartDateDesc(Long userId);
    
    /**
     * Get weekly progress for a user within a date range
     */
    @Query("SELECT wp FROM WeeklyProgress wp WHERE wp.userId = :userId " +
           "AND wp.weekStartDate >= :startDate AND wp.weekEndDate <= :endDate " +
           "ORDER BY wp.weekStartDate DESC")
    List<WeeklyProgress> findByUserIdAndDateRange(@Param("userId") Long userId,
                                                   @Param("startDate") LocalDate startDate,
                                                   @Param("endDate") LocalDate endDate);
    
    /**
     * Get the most recent N weeks of progress for a user
     */
    @Query("SELECT wp FROM WeeklyProgress wp WHERE wp.userId = :userId " +
           "ORDER BY wp.weekStartDate DESC")
    List<WeeklyProgress> findTopNByUserId(@Param("userId") Long userId);
    
    /**
     * Check if weekly progress exists for a user and week
     */
    boolean existsByUserIdAndWeekStartDate(Long userId, LocalDate weekStartDate);
    
    /**
     * Delete weekly progress for a specific user and week
     */
    void deleteByUserIdAndWeekStartDate(Long userId, LocalDate weekStartDate);
    
    /**
     * Get weekly progress statistics for the last N weeks
     */
    @Query("SELECT COUNT(wp), " +
           "COALESCE(AVG(wp.totalSteps), 0), " +
           "COALESCE(MAX(wp.totalSteps), 0), " +
           "COALESCE(SUM(wp.totalSteps), 0) " +
           "FROM WeeklyProgress wp WHERE wp.userId = :userId " +
           "AND wp.weekStartDate >= :startDate")
    Object[] getWeeklyStatistics(@Param("userId") Long userId, @Param("startDate") LocalDate startDate);
}
