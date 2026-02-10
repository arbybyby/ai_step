package com.arbybyby.aistep.ai_step_backend.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {
    
    // Exchange name
    public static final String MEALS_EXCHANGE = "meals.exchange";
    
    // Queue names
    public static final String ADD_MEAL_QUEUE = "meals.add.queue";
    public static final String DELETE_MEAL_QUEUE = "meals.delete.queue";
    
    // Routing keys
    public static final String ADD_MEAL_ROUTING_KEY = "meals.add";
    public static final String DELETE_MEAL_ROUTING_KEY = "meals.delete";

    @Bean
    public DirectExchange mealsExchange() {
        return new DirectExchange(MEALS_EXCHANGE);
    }

    @Bean
    public Queue addMealQueue() {
        return new Queue(ADD_MEAL_QUEUE, true); // durable = true
    }

    @Bean
    public Queue deleteMealQueue() {
        return new Queue(DELETE_MEAL_QUEUE, true); // durable = true
    }

    @Bean
    public Binding addMealBinding(Queue addMealQueue, DirectExchange mealsExchange) {
        return BindingBuilder.bind(addMealQueue)
                .to(mealsExchange)
                .with(ADD_MEAL_ROUTING_KEY);
    }

    @Bean
    public Binding deleteMealBinding(Queue deleteMealQueue, DirectExchange mealsExchange) {
        return BindingBuilder.bind(deleteMealQueue)
                .to(mealsExchange)
                .with(DELETE_MEAL_ROUTING_KEY);
    }

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
