package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.User;
import org.springframework.stereotype.Repository;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Repository
public class InMemoryUserRepository {
    private final Map<Long, User> userData = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    public User save(User user) {
        if (user.getId() == null) {
            user.setId(idGenerator.getAndIncrement());
        }
        userData.put(user.getId(), user);
        return user;
    }

    public Optional<User> findById(Long id) {
        return Optional.ofNullable(userData.get(id));
    }

    public Optional<User> findByEmail(String email) {
        return userData.values().stream()
                .filter(user -> Objects.equals(user.getEmail(), email))
                .findFirst();
    }

    public List<User> findAll() {
        return new ArrayList<>(userData.values());
    }

    public void deleteById(Long id) {
        userData.remove(id);
    }

    public void delete(User user) {
        userData.remove(user.getId());
    }

    public boolean existsByEmail(String email) {
        return userData.values().stream()
                .anyMatch(user -> Objects.equals(user.getEmail(), email));
    }

    public long count() {
        return userData.size();
    }

    public boolean existsById(Long id) {
        return userData.containsKey(id);
    }

    public void deleteAll() {
        userData.clear();
    }
}