package com.arbybyby.aistep.ai_step_backend.config;

import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {
    
    // Exchange names
    public static final String MEALS_EXCHANGE = "meals-exchange";
    public static final String USERS_EXCHANGE = "users.exchange";
    
    // Queue names
    public static final String ADD_MEAL_QUEUE = "meals.add.queue";
    public static final String DELETE_MEAL_QUEUE = "meals.delete.queue";
    public static final String USER_QUEUE = "users.queue";
    
    // Routing keys
    public static final String ADD_MEAL_ROUTING_KEY = "meals.add";
    public static final String DELETE_MEAL_ROUTING_KEY = "meals.delete";
    public static final String USER_ROUTING_KEY = "users.submit";
    public static final String AVATAR_ROUTING_KEY = "users.avatar";

    // Avatar exchange and queue
    public static final String AVATARS_EXCHANGE = "avatars.exchange";
    public static final String AVATAR_QUEUE = "avatars.queue";

    // Exchange, Queue и Binding создаются вручную в RabbitMQ
    // Java приложение только отправляет сообщения, не создавая инфраструктуру

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(jsonMessageConverter());
        return rabbitTemplate;
    }
}
