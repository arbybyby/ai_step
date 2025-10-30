package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.WeeklyProgressResponse;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.WeeklyProgressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * REST Controller for Weekly Progress endpoints
 */
@CrossOrigin(
    origins = {"http://localhost:*", "http://192.168.1.82:*", "https://*"}, 
    allowedHeaders = {"*"}, 
    methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS},
    allowCredentials = "true",
    maxAge = 3600
)
@RestController
@RequestMapping("/api/weekly-progress")
public class WeeklyProgressController {

    @Autowired
    private WeeklyProgressService weeklyProgressService;

    /**
     * Get current week's progress
     * GET /api/weekly-progress/current
     */
    @GetMapping("/current")
    public ResponseEntity<?> getCurrentWeekProgress(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/current ===");
            System.out.println("User ID: " + userId);

            WeeklyProgressResponse progress = weeklyProgressService.getCurrentWeekProgress(userId);

            System.out.println("Response: Current week progress retrieved");
            System.out.println("Total steps: " + progress.getTotalSteps());
            System.out.println("Daily breakdown size: " + 
                (progress.getDailyBreakdown() != null ? progress.getDailyBreakdown().size() : 0));
            
            // Wrap in "data" field for consistency with other endpoints
            return ResponseEntity.ok(Map.of("data", progress));

        } catch (Exception e) {
            System.err.println("Error fetching current week progress: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch current week progress", "details", e.getMessage()));
        }
    }

    /**
     * Get progress for a specific week
     * GET /api/weekly-progress/week?date=2024-10-28
     */
    @GetMapping("/week")
    public ResponseEntity<?> getWeekProgress(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/week ===");
            System.out.println("User ID: " + userId);
            System.out.println("Date: " + date);

            WeeklyProgressResponse progress = weeklyProgressService.getWeekProgress(userId, date);

            System.out.println("Response: Week progress retrieved for date " + date);
            
            // Wrap in "data" field for consistency
            return ResponseEntity.ok(Map.of("data", progress));

        } catch (Exception e) {
            System.err.println("Error fetching week progress: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch week progress", "details", e.getMessage()));
        }
    }

    /**
     * Get last N weeks of progress
     * GET /api/weekly-progress/last?weeks=4
     */
    @GetMapping("/last")
    public ResponseEntity<?> getLastNWeeks(
            @RequestParam(defaultValue = "4") int weeks,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/last ===");
            System.out.println("User ID: " + userId);
            System.out.println("Number of weeks: " + weeks);

            if (weeks < 1 || weeks > 52) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Number of weeks must be between 1 and 52"));
            }

            List<WeeklyProgressResponse> progressList = weeklyProgressService.getLastNWeeks(userId, weeks);

            System.out.println("Response: Retrieved " + progressList.size() + " weeks of progress");
            return ResponseEntity.ok(Map.of(
                    "weeks", progressList,
                    "count", progressList.size()
            ));

        } catch (Exception e) {
            System.err.println("Error fetching last N weeks: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch weekly progress", "details", e.getMessage()));
        }
    }

    /**
     * Get weekly progress within a date range
     * GET /api/weekly-progress/range?startDate=2024-10-01&endDate=2024-10-31
     */
    @GetMapping("/range")
    public ResponseEntity<?> getWeeklyProgressInRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/range ===");
            System.out.println("User ID: " + userId);
            System.out.println("Start date: " + startDate);
            System.out.println("End date: " + endDate);

            if (startDate.isAfter(endDate)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Start date must be before or equal to end date"));
            }

            List<WeeklyProgressResponse> progressList = weeklyProgressService
                    .getWeeklyProgressInRange(userId, startDate, endDate);

            System.out.println("Response: Retrieved " + progressList.size() + " weeks in range");
            return ResponseEntity.ok(Map.of(
                    "weeks", progressList,
                    "count", progressList.size(),
                    "startDate", startDate.toString(),
                    "endDate", endDate.toString()
            ));

        } catch (Exception e) {
            System.err.println("Error fetching weekly progress in range: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch weekly progress", "details", e.getMessage()));
        }
    }

    /**
     * Get all weekly progress for a user
     * GET /api/weekly-progress/all
     */
    @GetMapping("/all")
    public ResponseEntity<?> getAllWeeklyProgress(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/all ===");
            System.out.println("User ID: " + userId);

            List<WeeklyProgressResponse> progressList = weeklyProgressService.getAllWeeklyProgress(userId);

            System.out.println("Response: Retrieved all " + progressList.size() + " weeks");
            return ResponseEntity.ok(Map.of(
                    "weeks", progressList,
                    "count", progressList.size()
            ));

        } catch (Exception e) {
            System.err.println("Error fetching all weekly progress: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch weekly progress", "details", e.getMessage()));
        }
    }

    /**
     * Get weekly statistics summary
     * GET /api/weekly-progress/statistics?weeks=12
     */
    @GetMapping("/statistics")
    public ResponseEntity<?> getWeeklyStatistics(
            @RequestParam(defaultValue = "12") int weeks,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== GET /api/weekly-progress/statistics ===");
            System.out.println("User ID: " + userId);
            System.out.println("Number of weeks: " + weeks);

            if (weeks < 1 || weeks > 52) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Number of weeks must be between 1 and 52"));
            }

            Map<String, Object> statistics = weeklyProgressService.getWeeklyStatisticsSummary(userId, weeks);

            System.out.println("Response: Weekly statistics calculated");
            return ResponseEntity.ok(statistics);

        } catch (Exception e) {
            System.err.println("Error fetching weekly statistics: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch weekly statistics", "details", e.getMessage()));
        }
    }

    /**
     * Recalculate weekly progress for a date range (admin/maintenance endpoint)
     * POST /api/weekly-progress/recalculate?startDate=2024-10-01&endDate=2024-10-31
     */
    @PostMapping("/recalculate")
    public ResponseEntity<?> recalculateWeeklyProgress(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== POST /api/weekly-progress/recalculate ===");
            System.out.println("User ID: " + userId);
            System.out.println("Start date: " + startDate);
            System.out.println("End date: " + endDate);

            if (startDate.isAfter(endDate)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Start date must be before or equal to end date"));
            }

            weeklyProgressService.recalculateAllWeeklyProgress(userId, startDate, endDate);

            System.out.println("Response: Weekly progress recalculated");
            return ResponseEntity.ok(Map.of(
                    "message", "Weekly progress recalculated successfully",
                    "startDate", startDate.toString(),
                    "endDate", endDate.toString()
            ));

        } catch (Exception e) {
            System.err.println("Error recalculating weekly progress: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to recalculate weekly progress", "details", e.getMessage()));
        }
    }

    /**
     * Delete weekly progress for a specific week
     * DELETE /api/weekly-progress/week?date=2024-10-28
     */
    @DeleteMapping("/week")
    public ResponseEntity<?> deleteWeekProgress(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            System.out.println("=== DELETE /api/weekly-progress/week ===");
            System.out.println("User ID: " + userId);
            System.out.println("Date: " + date);

            LocalDate weekStart = date.with(java.time.DayOfWeek.MONDAY);
            weeklyProgressService.deleteWeekProgress(userId, weekStart);

            System.out.println("Response: Week progress deleted");
            return ResponseEntity.ok(Map.of(
                    "message", "Weekly progress deleted successfully",
                    "weekStartDate", weekStart.toString()
            ));

        } catch (Exception e) {
            System.err.println("Error deleting week progress: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to delete week progress", "details", e.getMessage()));
        }
    }
}
